Feature: Android support

Scenario: Make a simple GET request
  Given the element "trigger_error" is present
  When I click the element "trigger_error"
  Then I wait to receive a request
