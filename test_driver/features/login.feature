Feature: Login

  Scenario: User logs in successfully
    Given I am on the login screen
    When I fill the "email" field with "test@example.com"
    And I fill the "password" field with "password123"
    And I tap the "Login" button
    Then I expect to see "Welcome" 