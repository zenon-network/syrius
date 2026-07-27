@chain
Feature: Create sentinel stepper

  Scenario Outline: Creating a sentinel through the stepper registers the expected sentinel
    Given <sentinel_owner> devnet sentinel owner is prepared for creating a sentinel
    When I create a sentinel from the Create Sentinel stepper for <sentinel_owner>
    Then the blockchain should contain a sentinel for <sentinel_owner>

    Examples:
      | sentinel_owner                             |
      | 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d' |
