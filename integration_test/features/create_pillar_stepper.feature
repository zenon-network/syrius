@chain
Feature: Create pillar stepper

  Scenario: Creating a pillar through the stepper registers the expected pillar
    Given the devnet pillar owner is prepared for creating testPillar
    When I create pillar testPillar from the Create Pillar stepper
    Then the blockchain should contain pillar testPillar with the submitted stepper data
