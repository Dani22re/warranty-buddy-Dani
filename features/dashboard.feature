Feature: Basic Warranty Dashboard Flow
  As a user
  I want to connect Gmail (mock), upload my receipts, and see all my warranties in one place
  So I can easily track and manage them without losing anything.

  Background:
    Given the app is running

  Scenario: First visit to the dashboard
    When I go to "/"
    Then I should see "Warranty Buddy  -  Iteration 1"
    And I should see "Your Digital Memory for Every Purchase"
    And I should see a button "Connect Gmail (Mock)"
    And I should see "Not Connected"
    And I should see a form to upload a new receipt
    And the warranties table should be empty
