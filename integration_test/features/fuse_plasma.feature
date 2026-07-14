@chain
Feature: Fuse plasma

  Scenario Outline: Fusing QSR from the wallet UI is recorded on-chain
    Given <fuse_address> address has funds for fusing <amount> QSR
    When I fuse <amount> QSR to <fuse_address> from the Fuse Plasma card
    Then the published fuse block should match <fuse_address>, <fuse_address>, and <amount> QSR
    And <fuse_address> address should have at least <expected_plasma> plasma

    Examples:
      | fuse_address                               | amount | expected_plasma |
      | 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d' | '50'   | '105000'        |
