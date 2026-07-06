@chain
Feature: Create stake

  Scenario Outline: Creating a stake from the wallet UI is recorded on-chain
    Given <stake_address> address has funds for staking <amount> ZNN
    When I create a <duration_months> month stake of <amount> ZNN from <stake_address>
    Then the blockchain should contain that <duration_months> month stake of <amount> ZNN from <stake_address>

    Examples:
      | stake_address                              | duration_months | amount |
      | 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d' | '3'             | '100'  |
