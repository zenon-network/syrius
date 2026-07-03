# Create Pillar Stepper Security Testing Plan

## Goal

Prove that the Create Pillar stepper does not steal or misroute user funds.

The most important tests are real devnet integration tests that inspect the blockchain after fund-moving UI actions. Mocked tests are useful only as support; they cannot prove what was actually signed and published on-chain.

## Testing Priority

Use this order:

1. Add devnet integration test for plasma fusion when plasma is insufficient.
2. Add devnet integration test for QSR deposit.
3. Add devnet integration test for pillar deployment/registration.
4. Add minimal mocked widget tests only for input-to-event wiring if needed.
5. Add QSR withdraw integration test later if withdraw is in scope.

Do not spend time writing broad stepper widget tests for every UI state before the security tests exist.

## Hash-Based Blockchain Validation

The purpose of these integration tests is to validate that the data sent from the wallet matches the data found on-chain.

For fund-moving wallet actions, the wallet publishes an account block and receives an account-block hash back from the SDK/node. The test should use that hash as the authoritative reference for the action under test.

Validation pattern:

1. Drive the real wallet UI action.
2. Capture the returned `AccountBlockTemplate` or published account-block hash from the BLoC/action result.
3. Poll `zenon.ledger.getAccountBlockByHash(hash)` until the block is available on-chain.
4. Assert the fetched block exists.
5. Assert the fetched block hash equals the returned hash.
6. Assert the fetched block fields match the original UI inputs used to create the block.

For example, when sending a transfer, the UI submits recipient, token, and amount. The wallet publishes a send block and receives a hash. The test fetches the block with that hash and asserts that the on-chain block has the same recipient, token, and amount that were submitted from the UI.

Use the same mechanism for plasma fusion, QSR deposit, pillar deployment, and QSR withdraw.

## Test 0: Plasma Fusion Publishes Expected Block

This test is required when the deterministic devnet sender has enough funds for pillar creation but does not have enough plasma.

Pillar tests must not continue until the sender has enough plasma. If plasma is insufficient, run the real plasma fusion flow and verify the fund-safety of that fusion action before moving on to QSR deposit or pillar deployment tests.

Suggested scenario:

```gherkin
Scenario: Fusing plasma for pillar creation publishes the expected block
```

Drive the real UI:

1. Select a deterministic devnet sender with enough funds but insufficient plasma.
2. Open the flow that fuses plasma for the selected address.
3. Enter or accept the fusion amount required by the UI.
4. Click fuse and confirm.
5. Capture the account-block hash returned by the fuse action.
6. Fetch the published block by hash.
7. Poll plasma info until the selected address has enough plasma for pillar creation.

Assert:

- A block exists for the returned fuse hash.
- The fetched block hash equals the returned hash.
- The fetched block address equals the selected sender address.
- The fetched block destination is the expected embedded plasma contract.
- The fetched block token standard is QSR.
- The fetched block amount equals the fusion amount shown or entered in the UI.
- The fetched block data decodes to the expected plasma `Fuse` operation.
- The decoded plasma beneficiary is the selected wallet address.
- After confirmation, `currentPlasma >= kPillarPlasmaAmountNeeded`.

This test should fail if the wallet displays a safe plasma fusion flow but the block found by the returned hash contains different data.

## Test 1: QSR Deposit Publishes Expected Block

This is the highest-priority test because the user intentionally moves QSR during pillar creation.

Suggested scenario:

```gherkin
Scenario: Depositing QSR for pillar creation publishes the expected block
```

Drive the real UI:

1. Start from a deterministic devnet wallet with QSR available.
2. Open the Create Pillar stepper.
3. Continue past the plasma step.
4. Enter or accept the QSR deposit amount.
5. Click deposit and confirm.
6. Capture the account-block hash returned by the deposit action.
7. Fetch the published block by hash.

Assert:

- A block exists for the returned deposit hash.
- The fetched block hash equals the returned hash.
- The fetched block address equals the selected sender address.
- The fetched block destination is the expected embedded pillar contract.
- The fetched block token standard is QSR.
- The fetched block amount equals the amount shown or entered in the UI.
- The fetched block data decodes to the expected QSR deposit operation.

This test should fail if the wallet displays a safe QSR deposit flow but the block found by the returned hash contains different data.

## Test 2: Pillar Deployment Publishes Expected Block

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
9. Capture the account-block hash returned by the pillar registration action.
10. Fetch the published block by hash.

Assert:

- A block exists for the returned registration hash.
- The fetched block hash equals the returned hash.
- The fetched block address equals the selected sender address.
- The fetched block destination is the expected embedded pillar contract.
- The fetched block token standard is ZNN.
- The fetched block amount equals the expected pillar registration amount.
- The fetched block data decodes to the expected pillar registration operation.
- The decoded pillar name equals the value typed in the UI.
- The decoded reward address equals the value typed in the UI.
- The decoded producer address equals the value typed in the UI.
- The decoded reward percentages equal the values selected in the UI.

This test should fail if the UI displays safe values but the block found by the returned hash contains different values.

## Test 3: QSR Withdraw Publishes Expected Block

Add this only if QSR withdraw is part of the security scope.

Suggested scenario:

```gherkin
Scenario: Withdrawing pillar QSR publishes the expected block
```

Assert:

- A block exists for the returned withdraw hash.
- The fetched block hash equals the returned hash.
- The fetched block address equals the selected sender address.
- The fetched block destination is the expected embedded pillar contract.
- The fetched block data decodes to the expected QSR withdraw operation.
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
- Prepare required funds and plasma before the action under test.
- Assert required funds and plasma as preconditions before continuing.
- Drive the real Flutter UI, not SDK methods directly.
- Capture the account-block hash returned by the wallet action.
- Fetch the published account block by hash.
- Assert the block found on-chain matches the original UI inputs.
- Use randomized pillar names and recipient/reward addresses where practical.
- Fail with clear diagnostics showing the returned hash, the expected UI inputs, and the fetched block fields when an assertion fails.

## Plasma As Test Setup

Some deterministic devnet addresses may have enough funds for pillar creation but not enough plasma.

For QSR deposit and pillar deployment tests, sufficient plasma is a prerequisite. However, if plasma is insufficient, the fusion action must also be tested for fund safety before those tests continue.

Recommended pattern:

```text
beforeEach:
  select deterministic devnet sender
  ensure sender has required ZNN and QSR
  if sender plasma is insufficient:
    run the plasma fusion fund-safety flow
  assert required ZNN, QSR, and plasma preconditions

test:
  perform the QSR deposit or pillar deploy action through the real UI
  capture the returned account-block hash
  fetch the account block by hash
  assert the fetched block matches the original UI inputs
```

Do not use account-chain snapshots or counts as the primary validation mechanism. Plasma fusion, QSR deposit, and pillar deployment should each validate the exact block returned by the wallet action using its hash.

Before starting the measured UI action, explicitly assert:

- Sender has enough ZNN for the scenario.
- Sender has enough QSR for the scenario.
- Sender has `currentPlasma >= kPillarPlasmaAmountNeeded`.

If plasma is still insufficient after the fusion flow, fail early with a clear setup error, for example:

```text
Test setup failed: pillar sender does not have enough plasma
```

The plasma fusion fund-safety flow may be implemented as a reusable helper, but it must still validate the block returned by the fusion transaction hash when it creates a fusion transaction.

## Rule Of Thumb

For fund-safety claims, mocked tests are not enough.

The essential proof is:

```text
What the user saw in the UI == what was signed == what appeared on-chain
```

We validate that by fetching the published block by hash and comparing its on-chain fields with the initial data used by the wallet action.

For example:

```text
send transfer input -> returned hash -> on-chain block for hash -> same recipient/token/amount
```
