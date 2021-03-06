When(/^I send an? "(.+)"-type request$/) do |request_type|
  steps %Q{
    When I set environment variable "request_type" to "#{request_type}"
    And I set environment variable "MOCK_API_PORT" to "9339"
    And I run the script "features/scripts/send_request.sh" synchronously
  }
end
