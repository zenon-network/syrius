@chain
Feature: Send ZNN on devnet

  Scenario Outline: Sending ZNN from the wallet UI is recorded on-chain
    Given <sender> address has funds
    When I send <amount> ZNN from <sender> address to <recipient> address from the Send screen
    Then the blockchain should contain that <amount> ZNN transfer to <recipient>

    Examples:
      | sender                                      | recipient                                   | amount  |
      | 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e'  | 'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth'  | '0.001' |
