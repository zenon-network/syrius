@chain
Feature: Create token stepper

  Scenario: Creating a token through the stepper issues the expected token
    Given the devnet token owner is prepared for issuing NewToken
    When I create NewToken from the Create Token stepper
    Then the blockchain should contain NewToken with the submitted stepper data
