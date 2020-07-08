# @!group App Automator steps

# Checks a UI element is present
# Requires a running Appium driver
#
# @step_input element_id [String] The locator id
Given("the element {string} is present") do |element_id|
  present = $driver.wait_for_element(element_id)
  assert(present, "The element #{element_id} could not be found")
end

# Clicks a given element
# Requires a running Appium driver
#
# @step_input element_id [String] The locator id
When("I click the element {string}") do |element_id|
  $driver.click_element(element_id)
end

# Sends the app to the background for a number of seconds
# Requires a running Appium driver
#
# @step_input timeout [Integer] The amount of time the app is in the background in seconds
When("I send the app to the background for {int} seconds") do |timeout|
  $driver.background_app(timeout)
end

# Sends keys to a given element
# Requires a running Appium driver
#
# @step_input keys [String] The keys to send to the element
# @step_input element_id [String] The locator id
When("I send the keys {string} to the element {string}") do |keys, element_id|
  $driver.send_keys_to_element(element_id, keys)
end

# Tests that the given payload value is correct for the target BrowserStack platform.
# If the step is invoked when a remote BrowserStack device is not in use this step will fail.
#
# The DataTable used for this step should have `ios` and `android` in the same row as their expected value:
#   | android | Java.lang.RuntimeException |
#   | ios     | NSException                |
#
# @step_input field_path [String] The field to test
# @step_input platform_values [DataTable] A table of acceptable values for each platform
Then("the event {string} matches the correct platform value:") do |field_path, platform_values|
  if !defined?($driver) || $driver.nil?
    fail("This step should only be used if the AppAutomateDriver is present")
  end
  os = $driver.capabilities['os']
  expected_value = Hash[platform_values.raw][os]
  fail("There is no expected value for the current platform \"#{os}\"") if expected_value.nil?
  assert_equal(expected_value, read_key_path(Server.current_request[:body], field_path))
end