# Create Pillar Stepper Security Testing Plan

## Goal

Prove that the Create Pillar stepper does not steal or misroute user funds.

The most important tests are real devnet integration tests that inspect the blockchain after fund-moving UI actions. Mocked tests are useful only as support; they cannot prove what was actually signed and published on-chain.

## Testing Priority

Use this order:

1. Add devnet integration test for QSR deposit.
2. Add devnet integration test for pillar deployment/registration.
3. Add minimal mocked widget tests only for input-to-event wiring if needed.
4. Add QSR withdraw integration test later if withdraw is in scope.

Do not spend time writing broad stepper widget tests for every UI state before the security tests exist.

## Test 1: QSR Deposit Does Not Misroute Funds

This is the highest-priority test because the user intentionally moves QSR during pillar creation.

Suggested scenario:

```gherkin
Scenario: Depositing QSR for pillar creation sends funds only to the pillar contract
```

Drive the real UI:

1. Start from a deterministic devnet wallet with QSR available.
2. Open the Create Pillar stepper.
3. Continue past the plasma step.
4. Enter or accept the QSR deposit amount.
5. Click deposit and confirm.
6. Wait until the account block is published and available on-chain.

Before the action, record the sender account-chain height or latest block hash.

After the action, fetch all new outgoing account blocks from the sender.

Assert:

- Exactly one new outgoing block was created by this UI action.
- The block is the expected QSR deposit operation.
- The token standard is QSR.
- The amount equals the amount shown or entered in the UI.
- The destination is the expected embedded pillar contract, not a user-controlled address.
- No ZNN transfer was created.
- No QSR transfer was created to any unexpected address.
- No additional outgoing blocks were created.

This test should fail if malicious or buggy code sends any extra funds away while depositing QSR.

## Test 2: Pillar Deployment Registers Exact User Inputs

This is the second-highest-priority test because pillar deployment locks/registers meaningful funds and includes user-provided addresses.

Suggested scenario:

```gherkin
Scenario: Deploying a pillar registers the exact details entered by the user
```

Drive the real UI:

1. Start from a deterministic devnet wallet that already satisfies the required plasma, QSR, and ZNN conditions.
2. Open the Create Pillar stepper.
3. Continue to the deploy/register step.
4. Enter a randomized pillar name.
5. Enter a reward address controlled by the test wallet.
6. Enter a producer address controlled by the test wallet.
7. Choose reward percentages.
8. Click register and confirm.
9. Wait until the account block is published and available on-chain.

Before the action, record the sender account-chain height or latest block hash.

After the action, fetch all new outgoing account blocks from the sender.

Assert:

- Exactly one new outgoing block was created by this UI action.
- The block is the expected pillar registration operation.
- The destination is the expected embedded pillar contract.
- The pillar name equals the value typed in the UI.
- The reward address equals the value typed in the UI.
- The producer address equals the value typed in the UI.
- The reward percentages equal the values selected in the UI.
- The ZNN amount equals the expected pillar registration amount.
- No outgoing transfer was created to an unexpected address.
- No extra ZNN or QSR transfer was created.
- No additional outgoing blocks were created.

This test should fail if the UI displays safe values but the signed block contains different values.

## Test 3: QSR Withdraw Does Not Misroute Returned Funds

Add this only if QSR withdraw is part of the security scope.

Suggested scenario:

```gherkin
Scenario: Withdrawing pillar QSR does not create an unexpected outgoing transfer
```

Assert:

- The withdraw request goes to the expected embedded pillar contract.
- No outgoing user-to-user transfer is created.
- No extra ZNN or QSR outgoing transfer is created.
- Any returned or claimable QSR belongs to the expected wallet/address.

This test is lower priority than deposit and deployment because it is less likely to be a direct theft vector, but it is still useful for fund-safety confidence.

## Minimal Mocked Tests

Keep mocked tests small and only where they support the integration tests.

Useful mocked tests:

- QSR deposit button dispatches `PillarDepositQsrRequested` with the selected address and displayed amount.
- Deploy button dispatches `DeployPillarRequested` with the exact pillar name, reward address, producer address, and reward percentages from the UI.
- Invalid recipient/producer addresses keep the deploy button disabled.

Avoid mocked tests that duplicate BLoC behavior already covered in:

- `test/deploy_pillar/bloc/deploy_pillar_bloc_test.dart`
- `test/create_pillar_qsr_info/bloc/create_pillar_qsr_info_bloc_test.dart`
- `test/pillar_deposit_qsr/bloc/pillar_deposit_qsr_bloc_test.dart`
- `test/pillar_withdraw_qsr/bloc/pillar_withdraw_qsr_bloc_test.dart`

## What Not To Prioritize

Do not prioritize these before the security integration tests:

- Testing every stepper loading state.
- Testing every visual state.
- Testing every disabled button condition.
- Large mocked full-stepper happy paths that never inspect the blockchain.

Those tests can improve maintainability, but they do not prove that user funds are safe.

## Integration Test Requirements

Each security integration test should:

- Use a fresh or deterministic local devnet state.
- Use a deterministic devnet-only wallet.
- Drive the real Flutter UI, not SDK methods directly.
- Record sender chain state before the action.
- Fetch new sender account blocks after the action.
- Assert both the expected block and the absence of unexpected outgoing blocks.
- Use randomized pillar names and recipient/reward addresses where practical.
- Fail with clear diagnostics showing all new outgoing blocks when an assertion fails.

## Rule Of Thumb

For fund-safety claims, mocked tests are not enough.

The essential proof is:

```text
What the user saw in the UI == what was signed == what appeared on-chain
```

And also:

```text
No extra outgoing transfer happened during the action
```
