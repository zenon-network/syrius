@chain
Feature: Create pillar QSR deposit

  Scenario Outline: Depositing QSR for pillar creation publishes the expected block
    Given <sender> address is prepared for pillar creation with at least <required_plasma> plasma using <setup_qsr_fuse_amount> QSR if needed
    When I deposit the required QSR from <sender> address in the Create Pillar stepper
    Then the published pillar QSR deposit block should match <sender>

    Examples:
      | sender                                      | required_plasma | setup_qsr_fuse_amount |
      | 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e'  | '252000'        | '120'                 |
