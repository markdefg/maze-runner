# frozen_string_literal: true

require 'cucumber'
require 'json'
require 'securerandom'

AfterConfiguration do |config|

  # Start mock server
  Server.start_server
  config = MazeRunner.config
  next if config.farm == :none

  # Setup Appium capabilities.  Note that the 'app' capability is
  # set in a hook as it will change if uploaded to BrowserStack.

  # BrowserStack specific setup
  if config.farm == :bs
    tunnel_id = SecureRandom.uuid
    config.capabilities = Capabilities.for_browser_stack config.bs_device,
                                                         tunnel_id,
                                                         config.appium_version,
                                                         config.capabilities_option

    config.app = BrowserStackUtils.upload_app config.username,
                                              config.access_key,
                                              config.app
    BrowserStackUtils.start_local_tunnel config.bs_local,
                                         tunnel_id,
                                         config.access_key
  elsif config.farm == :local
    config.capabilities = Capabilities.for_local config.os,
                                                 config.capabilities_option,
                                                 config.apple_team_id,
                                                 config.device_id
  end

  # Set app location (file or url) in capabilities
  config.capabilities['app'] = config.app

  # Create and start the relevant driver
  MazeRunner.driver = if MazeRunner.config.resilient
                        $logger.info 'Creating ResilientAppiumDriver instance'
                        ResilientAppiumDriver.new config.appium_server_url,
                                                  config.capabilities,
                                                  config.locator
                      else
                        $logger.info 'Creating AppiumDriver instance'
                        AppiumDriver.new config.appium_server_url,
                                         config.capabilities,
                                         config.locator
                      end
  if config.farm == :bs
    # Log a link to the BrowserStack session search dashboard
    build = MazeRunner.driver.caps[:build]
    url = "https://app-automate.browserstack.com/dashboard/v2/?searchQuery=#{build}"
    if ENV['BUILDKITE']
      $logger.info LogUtil.linkify url, 'BrowserStack session(s)'
    else
      $logger.info "BrowserStack session(s): #{url}"
    end
  end
  MazeRunner.driver.start_driver unless config.appium_session_isolation

  # Call any blocks registered by the client
  MazeRunner.hooks.call_after_configuration config
end

# Before each scenario
Before do |scenario|
  STDOUT.puts "--- Scenario: #{scenario.name}"

  Runner.environment.clear
  Server.stored_requests.clear
  Store.values.clear

  MazeRunner.driver.start_driver if MazeRunner.config.farm != :none && MazeRunner.config.appium_session_isolation

  # Launch the app on macOS
  MazeRunner.driver.get(MazeRunner.config.app) if MazeRunner.config.os == 'macos'

  # Call any blocks registered by the client
  MazeRunner.hooks.call_before scenario
end

# After each scenario
After do |scenario|

  # Call any blocks registered by the client
  MazeRunner.hooks.call_after scenario

  # Make sure we reset to HTTP 200 return status after each scenario
  Server.status_code = 200
  Server.reset_status_code = false

  # This is here to stop sessions from one test hitting another.
  # However this does mean that tests take longer.
  # In addition, reset the last captured exit code
  # TODO:SM We could try and fix this by generating unique endpoints
  # for each test.
  Docker.down_all_services
  Docker.last_exit_code = nil
  Docker.last_command_logs = nil

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

  next if MazeRunner.config.farm == :none

  if MazeRunner.config.appium_session_isolation
    MazeRunner.driver.driver_quit
  elsif MazeRunner.config.os == 'macos'
    # Close the app - without the sleep, launching the app for the next scenario intermittently fails
    system("killall #{MazeRunner.config.app} && sleep 1")
  else
    MazeRunner.driver.reset_with_timeout 2
  end
end

# After all tests
at_exit do

  STDOUT.puts '+++ All scenarios complete'

  # Stop the mock server
  Server.stop_server

  # In order to not impact future test runs, we down
  # all services (which removes networks etc) so that
  # future test runs are from a clean slate.
  Docker.down_all_services

  next if MazeRunner.config.farm == :none

  # Stop the Appium session
  MazeRunner.driver.driver_quit unless MazeRunner.config.appium_session_isolation
end


