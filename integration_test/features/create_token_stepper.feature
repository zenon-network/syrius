@chain
Feature: Create token stepper

  Scenario Outline: Creating a token through the stepper issues the expected token
    Given <token_owner> is prepared for issuing a token
    When I create a token with name <token_name>, symbol <token_symbol>, website <website>, mintable <mintable>, burnable <burnable>, decimals <decimals>, max supply <max_supply>, total supply <total_supply>, utility <utility> from the Create Token stepper
    Then the returned issue block from <token_owner> should contain <token_name>, <token_symbol>, <website>, <mintable>, <burnable>, <decimals>, <max_supply>, <total_supply>, and <utility>

    Examples:
      | token_owner                                | token_name | token_symbol | website       | mintable | burnable | decimals | max_supply | total_supply | utility |
      | 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d' | 'newToken' | 'TKK'        | 'testing.com' | 'true'   | 'true'   | '3'      | '100'      | '90'         | 'false' |
