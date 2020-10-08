# frozen_string_literal: true

require 'cucumber'
require 'json'

AfterConfiguration do |config|

  # Start mock server
  Server.start_server
  next if MazeRunner.configuration.farm == :no_farm

  # BrowserStack specific setup
  if MazeRunner.configuration.farm == :bs
    MazeRunner.configuration.app_location = BrowserStackUtils.upload_app(MazeRunner.configuration.username,
                                                                         MazeRunner.configuration.access_key,
                                                                         MazeRunner.configuration.app_location)
    BrowserStackUtils.start_local_tunnel(MazeRunner.configuration.bs_local,
                                         MazeRunner.configuration.access_key)
  end
  # Set app location (file or url) in capabilities
  MazeRunner.configuration.capabilities['app'] = MazeRunner.configuration.app_location

  # Create and start the drive
  MazeRunner.driver = ResilientAppiumDriver.new(MazeRunner.configuration.appium_server_url,
                                                MazeRunner.configuration.capabilities)
  MazeRunner.driver.start_driver unless MazeRunner.configuration.appium_session_isolation

  # TODO: Debugging ability to fetch actual OS version, which will be needed for @skipping.
  # One seems to only work on BrowserStack and the other only locally.
  # puts "Actual driver capabilities #{MazeRunner.driver.capabilities}"
  # puts 'Device info:'
  # puts JSON.pretty_generate MazeRunner.driver.device_info
  # puts 'Session capabilities:'
  # puts JSON.pretty_generate MazeRunner.driver.session_capabilities
end

# Before each scenario
Before do |scenario|
  STDOUT.puts "--- Scenario: #{scenario.name}"
  Runner.environment.clear
  Server.stored_requests.clear
  Store.values.clear

  next if MazeRunner.configuration.farm == :no_farm

  MazeRunner.driver.start_driver if MazeRunner.configuration.appium_session_isolation
end

# After each scenario
After do |scenario|

  # This is here to stop sessions from one test hitting another.
  # However this does mean that tests take longer.
  # TODO:SM We could try and fix this by generating unique endpoints
  # for each test.
  Docker.down_all_services

  # Make sure that any scripts are killed between test runs
  # so future tests are run from a clean slate.
  Runner.kill_running_scripts

  Proxy.instance.stop

  # Log unprocessed requests if the scenario fails
  if scenario.failed?
    STDOUT.puts '^^^ +++'
    if Server.stored_requests.empty?
      $logger.info 'No requests received'
    else
      $logger.info 'The following requests were received:'
      Server.stored_requests.each.with_index(1) do |request, number|
        $logger.info "Request #{number}:"
        LogUtil.log_hash(Logger::Severity::INFO, request)
      end
    end
  end

  next if MazeRunner.configuration.farm == :no_farm

  if MazeRunner.configuration.appium_session_isolation
    MazeRunner.driver.driver_quit
  else
    MazeRunner.driver.reset_with_timeout 2
  end
end

# After all tests
at_exit do
  # Stop the mock server
  Server.stop_server

  # In order to not impact future test runs, we down
  # all services (which removes networks etc) so that
  # future test runs are from a clean slate.
  Docker.down_all_services

  next if MazeRunner.configuration.farm == :no_farm

  # Stop the Appium session
  MazeRunner.driver.driver_quit unless MazeRunner.configuration.appium_session_isolation
end

