# frozen_string_literal: true

require 'cucumber'
require 'json'
require 'securerandom'
require 'selenium-webdriver'

AfterConfiguration do |_cucumber_config|

  # Start mock server
  Maze::Server.start
  config = Maze.config
  next if config.farm == :none

  # Setup Appium capabilities.  Note that the 'app' capability is
  # set in a hook as it will change if uploaded to BrowserStack.

  # BrowserStack specific setup
  if config.farm == :bs
    tunnel_id = SecureRandom.uuid
    if config.bs_device
      # BrowserStack device
      config.capabilities = Maze::Capabilities.for_browser_stack_device config.bs_device,
                                                                        tunnel_id,
                                                                        config.appium_version,
                                                                        config.capabilities_option

      config.app = Maze::BrowserStackUtils.upload_app config.username,
                                                      config.access_key,
                                                      config.app
      config.capabilities['app'] = config.app
    else
      # BrowserStack browser
      config.capabilities = Maze.for_browser_stack_browser config.bs_browser,
                                                           tunnel_id,
                                                           config.capabilities_option
    end
    Maze::BrowserStackUtils.start_local_tunnel config.bs_local,
                                               tunnel_id,
                                               config.access_key
  elsif config.farm == :local
    # Local device
    config.capabilities = Maze.for_local config.os,
                                                       config.capabilities_option,
                                                       config.apple_team_id,
                                                       config.device_id
    config.capabilities['app'] = config.app
  end

  # Create and start the relevant driver
  if config.bs_browser
    selenium_url = "http://#{config.username}:#{config.access_key}@hub.browserstack.com/wd/hub"
    Maze.driver = Maze::SeleniumDriver.new selenium_url, config.capabilities
  else
    Maze.driver = if Maze.config.resilient
                    $logger.info 'Creating ResilientAppium driver instance'
                    Maze::Driver::ResilientAppium.new config.appium_server_url,
                                                      config.capabilities,
                                                      config.locator
                  else
                    $logger.info 'Creating Appium driver instance'
                    Maze::Driver::Appium.new config.appium_server_url,
                                             config.capabilities,
                                             config.locator
                  end
    Maze.driver.start_driver unless config.appium_session_isolation
  end

  if config.farm == :bs && config.bs_device
    # Log a link to the BrowserStack session search dashboard
    build = Maze.driver.caps[:build]
    url = "https://app-automate.browserstack.com/dashboard/v2/search?query=#{build}&type=builds"
    if ENV['BUILDKITE']
      $logger.info Maze::LogUtil.linkify url, 'BrowserStack session(s)'
    else
      $logger.info "BrowserStack session(s): #{url}"
    end
  end

  # Call any blocks registered by the client
  Maze.hooks.call_after_configuration config
end

# Before each scenario
Before do |scenario|
  STDOUT.puts "--- Scenario: #{scenario.name}"

  Maze.driver.start_driver if Maze.config.farm != :none && Maze.config.appium_session_isolation

  # Launch the app on macOS
  Maze.driver.get(Maze.config.app) if Maze.config.os == 'macos'

  # Call any blocks registered by the client
  Maze.hooks.call_before scenario
end

# General processing to be run after each scenario
After do |scenario|

  # Call any blocks registered by the client
  Maze.hooks.call_after scenario

  # Make sure we reset to HTTP 200 return status after each scenario
  Maze::Server.status_code = 200
  Maze::Server.reset_status_code = false

  # This is here to stop sessions from one test hitting another.
  # However this does mean that tests take longer.
  # In addition, reset the last captured exit code
  # TODO:SM We could try and fix this by generating unique endpoints
  # for each test.
  Maze::Docker.reset

  # Make sure that any scripts are killed between test runs
  # so future tests are run from a clean slate.
  Maze::Runner.kill_running_scripts

  Maze::Proxy.instance.stop

  # Log unprocessed requests if the scenario fails
  if scenario.failed?
    STDOUT.puts '^^^ +++'
    if Maze::Server.sessions.empty?
      $logger.info 'No valid sessions received'
    else
      count = Maze::Server.sessions.size_all
      $logger.info "#{count} sessions were received:"
      Maze::Server.sessions.all.each.with_index(1) do |request, number|
        STDOUT.puts "--- Session #{number} of #{count}"
        Maze::LogUtil.log_hash(Logger::Severity::INFO, request)
      end
    end

    if Maze::Server.errors.empty?
      $logger.info 'No valid errors received'
    else
      count = Maze::Server.errors.size_all
      $logger.info "#{count} errors were received:"
      Maze::Server.errors.all.each.with_index(1) do |request, number|
        STDOUT.puts "--- Request #{number} of #{count}"
        Maze::LogUtil.log_hash(Logger::Severity::INFO, request)
      end
    end
  end

  if Maze.config.appium_session_isolation
    Maze.driver.driver_quit
  elsif Maze.config.os == 'macos'
    # Close the app - without the sleep, launching the app for the next scenario intermittently fails
    system("killall #{Maze.config.app} && sleep 1")
  elsif Maze.config.bs_device
    Maze.driver.reset_with_timeout 2
  end
ensure
  # Request arrays in particular are cleared here, rather than in the Before hook, to allow requests to be registered
  # when a test fixture starts (which can be before the first Before scenario hook fires).
  Maze::Server.errors.clear
  Maze::Server.sessions.clear
  Maze::Server.invalid_requests.clear
  Maze::Runner.environment.clear
  Maze::Store.values.clear
end

# Check for invalid requests after each scenario.  This is its own hook as failing a scenario raises an exception
# and we need the logic in the other After hook to be performed.
# Furthermore, this hook should appear after the general hook as they are executed in reverse order by Cucumber.
After do |scenario|
  unless Maze::Server.invalid_requests.empty?
    Maze::Server.invalid_requests.each.with_index(1) do |request, number|
      $logger.error "Invalid request #{number} (#{request[:reason]}):"
      Maze::LogUtil.log_hash(Logger::Severity::ERROR, request)
    end
    msg = "#{Maze::Server.invalid_requests.length} invalid request(s) received during scenario"
    scenario.fail msg
  end
end

# After all tests
at_exit do

  STDOUT.puts '+++ All scenarios complete'

  # Stop the mock server
  Maze::Server.stop

  # In order to not impact future test runs, we down
  # all services (which removes networks etc) so that
  # future test runs are from a clean slate.
  Maze::Docker.down_all_services

  next if Maze.config.farm == :none

  # Stop the Appium session
  Maze.driver.driver_quit unless Maze.config.appium_session_isolation
end


