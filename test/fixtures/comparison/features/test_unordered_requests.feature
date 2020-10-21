Feature: Unordered requests can be tested using a table

    Scenario: Testing payloads pass regardless of order
        When I send a "ordered 1"-type request
        And I send a "ordered 2"-type request
        And I wait to receive 2 requests
        Then the tests match the following:
          | foo | bar |
          | a   | b   |
          | b   | a   |
        And the tests match the following:
          | foo | bar |
          | b   | a   |
          | a   | b   |