@chain
Feature: Fuse plasma

  Scenario Outline: Fusing QSR publishes the expected plasma block
    Given <sender> address is selected for plasma fusion
    When I fuse <qsr_amount> QSR to <beneficiary>
    Then the published fuse block should match <sender>, <beneficiary>, and <qsr_amount> QSR
    And <beneficiary> address should have at least <expected_plasma> plasma

    Examples:
      | sender                                      | beneficiary                                 | qsr_amount | expected_plasma |
      | 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e'  | 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e'  | '120'      | '252000'        |
