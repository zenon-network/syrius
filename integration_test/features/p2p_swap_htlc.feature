@chain
Feature: P2P Swap HTLC

  Scenario Outline: Creating, joining, and completing an HTLC swap through the P2P Swap UI
    Given two funded devnet participants are prepared for a P2P HTLC swap
    When the initiator starts a P2P HTLC swap of <initial_amount> ZNN from the Start P2P Swap modal
    Then the blockchain should contain the created initial HTLC with the submitted swap parameters
    When the counterparty joins the P2P HTLC swap with <counter_amount> ZNN from the Join P2P Swap modal
    And the initiator completes the P2P HTLC swap from the P2P Swap modal
    Then the blockchain should record the unlocked HTLC swap for both participants

    Examples:
      | initial_amount | counter_amount |
      | '0.25'         | '0.15'         |
