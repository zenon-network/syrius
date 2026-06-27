@chain
Feature: Send ZNN on devnet

  Scenario: Sending ZNN from the wallet UI is recorded on-chain
    Given the devnet node is running
    And sender address {'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e'} has funds
    When I send {'0.001'} ZNN from sender address {'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e'} to recipient address {'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth'} from the Send screen
    Then the blockchain should contain that {'0.001'} ZNN transfer to {'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth'}
