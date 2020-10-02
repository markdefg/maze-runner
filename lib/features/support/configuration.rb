# frozen_string_literal: true

# MazeRunner configuration
class Configuration

  def initialize
    @appium_session_isolation = false
    @browser_stack_local = '/BrowserStackLocal'
  end

  # Whether each scenario should have its own Appium session
  attr_accessor :appium_session_isolation

  # Device farm to be used
  attr_accessor :farm

  # Location of the BrowserStackLocal binary (if used)
  attr_accessor :browser_stack_local

  # URL of the Appium server
  attr_accessor :appium_server_url

  # Location of the app (IPA or APK) that tests will be run against
  attr_accessor :app_location
end
