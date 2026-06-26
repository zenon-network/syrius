# Blockchain Integration Tests

## Purpose

Blockchain integration tests validate wallet behavior against a real devnet node. They should cover the full wallet path whenever practical: user input in the Flutter UI, BLoC/event handling, wallet signing, node submission, and blockchain state assertions.

For the initial scope, add a widget-driven send transaction test that enters a ZNN amount and recipient address in the Send UI, confirms the send action, and verifies that the devnet blockchain reflects the same amount, token, and recipient.

## Step-by-Step Setup

1. Make sure the Docker devnet node can start locally with one command and exposes its WebSocket RPC port.
2. Configure the devnet genesis or startup script so one deterministic test wallet starts with enough ZNN.
3. Choose a devnet-only sender mnemonic and recipient address for the test.
4. Add `bdd_widget_test` and `integration_test` as dev dependencies.
5. Configure `build.yaml` so `bdd_widget_test` generates tests from files under `integration_test/`.
6. Add stable keys to the Send UI fields and button so the generated test steps can reliably find them.
7. Add `integration_test/features/send_transaction.feature` with the Gherkin send scenario.
8. Generate the Dart test and step files with `dart run build_runner build --delete-conflicting-outputs`.
9. Implement the generated steps so they type the recipient and amount into the Send UI, confirm the dialog, and wait for the published account-block hash.
10. Poll the devnet node until the published block is available on-chain.
11. Assert that the on-chain block has the same recipient, ZNN token standard, and amount that was typed in the UI.
12. Add a GitHub Actions job that starts the Docker devnet, waits for it to be ready, and runs the generated integration test on Linux.
13. Add separate GitHub Actions build jobs for Linux, macOS, and Windows desktop release builds.

## Staged Rollout Plan

Use this staged approach when the integration-test infrastructure is developed in a fork first and moved to the original repository later.

### Stage 1: Build in the Fork

Add the full testing infrastructure in the fork first:

- `integration_test/features/send_transaction.feature`
- `integration_test/steps/`
- `integration_test/support/`
- `build.yaml` configuration for `bdd_widget_test`
- stable Send UI keys
- Docker devnet wait script
- a manual GitHub Actions workflow using `workflow_dispatch`

The first workflow should be manually triggered from the fork's Actions tab. This avoids requiring any changes or permissions in the original repository while the setup is still being proven.

### Stage 2: Use Fork Runs as PR Evidence

Before opening or updating a PR to the original repository:

1. Push the branch to the fork.
2. Manually run the blockchain integration workflow in the fork.
3. Confirm that the workflow passes.
4. Link the successful workflow run in the PR description or in a PR comment.

This is not as strong as a workflow run inside the original repository, but it gives maintainers a concrete proof-of-concept and a reproducible CI log.

### Stage 3: Add PR-Friendly Triggers in the Fork

After the manual workflow is stable, optionally add automatic fork-side triggers:

```yaml
on:
  workflow_dispatch:
  push:
    branches:
      - dev
      - integration-tests
  pull_request:
    branches:
      - dev
```

This keeps the fork self-validating while still avoiding any dependency on the original repository's CI configuration.

### Stage 4: Propose Migration to the Original Repository

Once the workflow is stable, propose moving the infrastructure upstream:

- Add the BDD integration test files.
- Add the devnet wait script.
- Add the `bdd_widget_test` and `integration_test` dependencies.
- Add or update `build.yaml`.
- Add the GitHub Actions workflow.

A safe first upstream version can be manual-only:

```yaml
on:
  workflow_dispatch:
```

After maintainers trust the setup, enable automatic PR checks against the original repository's `dev` branch:

```yaml
on:
  pull_request:
    branches:
      - dev
  workflow_dispatch:
```

### Stage 5: Security-Focused Assertions

The first security-oriented scenario should prove more than "the expected transfer exists". It should also check that no unexpected outgoing transfer happened during the tested action.

For the Send flow, record the sender account-chain state before the UI action, then inspect all new outgoing account blocks after the action and assert:

- the expected ZNN transfer exists
- the recipient equals the address typed into the UI
- the amount equals the amount typed into the UI
- the token standard is ZNN
- no additional outgoing ZNN transfers were created
- no outgoing transfer was created to an unexpected address

Use randomized recipient addresses and amounts where practical, so malicious code cannot easily special-case one hard-coded test value.

## Test Strategy

- Keep unit and BLoC tests mocked and fast under `test/`.
- Put blockchain tests under `integration_test/`.
- Drive the Send UI with Flutter test APIs instead of calling SDK send methods directly.
- Use the real `SendTransactionBloc` and `AccountBlockUtils` path where possible.
- Query the devnet node only for setup and final assertions.
- Poll for blockchain state because account blocks and momentum confirmation are eventually consistent.
- Start with one high-value send test before expanding coverage.

## BDD and Gherkin Scope

Use Gherkin/BDD only for blockchain integration tests. Keep unit, BLoC, utility, serialization, and small widget tests as normal Dart tests under `test/`.

The default BDD library for this repo is [`bdd_widget_test`](https://pub.dev/packages/bdd_widget_test). It generates Flutter widget tests from `.feature` files, so CI still runs normal Dart test files after code generation.

Recommended split:

```text
test/
  Fast mocked Dart tests for BLoCs, cubits, validators, serializers, utilities, and small widgets.

integration_test/
  Gherkin scenarios for high-level wallet journeys that run against the Dockerized devnet.
```

BDD is appropriate here because these tests describe user-visible behavior and verify real on-chain effects. It should not be used for low-level implementation tests where plain Dart tests are clearer and faster.

Good Gherkin candidates:

- Send ZNN from the Send UI.
- Receive a pending transaction.
- Delegate from the wallet UI.
- Stake from the wallet UI.
- Fuse plasma from the wallet UI.
- WalletConnect approval flows.

Avoid Gherkin for:

- BLoC state transition unit tests.
- Input validators.
- JSON serialization tests.
- Utility functions.
- Small rendering-only widget tests.

Suggested integration test layout:

```text
integration_test/
  features/
    send_transaction.feature
  steps/                 Generated by bdd_widget_test, then implemented by us.
    wallet_steps.dart
    send_steps.dart
    blockchain_steps.dart
  support/
    devnet_world.dart
    blockchain_polling.dart
    test_wallet.dart
```

Required dev dependencies:

```yaml
dev_dependencies:
  bdd_widget_test: ^2.1.4
  integration_test:
    sdk: flutter
```

`build_runner` already exists in this repo and is used by `bdd_widget_test` to generate Dart tests and step files from `.feature` files.

Configure `build.yaml` so code generation includes `integration_test/`. The exact final config can be adjusted when implementing the tests, but it should include these sources:

```yaml
targets:
  $default:
    sources:
      - integration_test/**
      - test/**
      - lib/**
      - $package$
    builders:
      bdd_widget_test|featureBuilder:
        options:
          relativeToTestFolder: false
          stepFolderName: integration_test/steps
```

Generate tests and steps with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do not manually edit generated Dart test files. Implement and maintain the generated step files and shared helpers instead.

Example feature file:

```gherkin
Feature: Send ZNN on devnet

  Scenario: Sending ZNN from the wallet UI is recorded on-chain
    Given I have a funded devnet wallet
    And the wallet is connected to the devnet node
    When I send 1.25 ZNN to a recipient from the Send screen
    Then the blockchain should contain a ZNN transfer of 1.25 to that recipient
    And the recipient should have an unreceived transaction for that transfer
```

Before adding broad BDD coverage, verify one generated `bdd_widget_test` scenario end-to-end with the current Flutter version, desktop integration tests, and the GitHub Actions Linux runner. Keep Gherkin execution limited to the devnet integration-test CI job.

## Devnet Requirements

The CI job should run a Dockerized devnet node locally inside the GitHub Actions runner. Avoid using a shared external devnet for PR checks because shared chain state makes tests flaky and can cause PRs to interfere with each other.

The Docker devnet should provide:

- A WebSocket RPC endpoint exposed to the runner, for example `ws://127.0.0.1:35998`.
- A clean chain state for each CI job.
- A deterministic funded test wallet or deterministic funded sender address in genesis.
- A deterministic recipient address or a way for tests to derive one.
- Non-interactive startup and shutdown.
- A reliable readiness condition, such as responding to `ledger.getFrontierMomentum` or `stats.syncInfo`.

## Environment Variables

Use environment variables so the same test can run locally and in CI:

```text
RUN_CHAIN_TESTS=true
ZNN_TEST_NODE_URL=ws://127.0.0.1:35998
ZNN_TEST_MNEMONIC=<devnet-only funded mnemonic>
ZNN_TEST_PASSWORD=test-password
ZNN_TEST_RECIPIENT_ADDRESS=<recipient address>
```

The mnemonic must be devnet-only. Do not use a real wallet or a mainnet-funded mnemonic in CI.

## Send Transaction Test Flow

The first integration test should verify that an amount typed into the wallet UI is the amount published on-chain.

Recommended flow:

1. Skip the test unless `RUN_CHAIN_TESTS=true`.
2. Connect the app SDK singleton to `ZNN_TEST_NODE_URL`.
3. Create or open a deterministic test wallet from `ZNN_TEST_MNEMONIC`.
4. Configure wallet globals used by the Send feature, including selected address and default address list.
5. Fetch the sender account info from the devnet and ensure it has enough ZNN.
6. Pump a widget tree containing the Send feature with real BLoC wiring.
7. Enter `ZNN_TEST_RECIPIENT_ADDRESS` into the recipient field.
8. Enter the test ZNN amount into the amount field.
9. Tap the Send button.
10. Confirm the dialog.
11. Wait for the send BLoC to report success and capture the returned account-block hash.
12. Poll `zenon.ledger.getAccountBlockByHash(hash)` until the block is available and confirmed, or until a timeout is reached.
13. Assert that the block recipient, amount, and token standard match the UI input.
14. Assert that the receiver has the sent block as an unreceived transaction via `getUnreceivedBlocksByAddress`, unless the test also drives the receive flow.

For the first version, prefer asserting the published send block and the receiver's unreceived transaction. Receiver balance assertions require a receive block, so they test a broader flow and should be added separately.

## Stable Widget Selectors

Before adding the integration test, add stable keys to the Send UI so tests do not depend on localized strings or widget ordering:

```dart
const Key('send_recipient_field')
const Key('send_amount_field')
const Key('send_submit_button')
```

These keys should be attached to the recipient field, amount field, and send button in the Send feature.

## GitHub Actions Shape

Use separate jobs for fast validation, desktop builds, and blockchain integration tests.

```yaml
jobs:
  analyze-and-unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test test

  desktop-build:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: linux
          - os: macos-latest
            target: macos
          - os: windows-latest
            target: windows
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ${{ matrix.target }} --release

  chain-integration-test:
    runs-on: ubuntu-latest
    services:
      devnet:
        image: ghcr.io/your-org/zenon-devnet:latest
        ports:
          - 35998:35998
    env:
      RUN_CHAIN_TESTS: "true"
      ZNN_TEST_NODE_URL: ws://127.0.0.1:35998
      ZNN_TEST_MNEMONIC: ${{ secrets.ZNN_TEST_MNEMONIC }}
      ZNN_TEST_PASSWORD: test-password
      ZNN_TEST_RECIPIENT_ADDRESS: ${{ vars.ZNN_TEST_RECIPIENT_ADDRESS }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: ./scripts/wait-for-devnet.sh
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter test integration_test -d linux
```

Adjust the Docker image, port, Linux desktop dependencies, and Flutter version to match the final CI environment.

## Local Run Shape

Run the devnet Docker container locally, then run:

```bash
RUN_CHAIN_TESTS=true \
ZNN_TEST_NODE_URL=ws://127.0.0.1:35998 \
ZNN_TEST_MNEMONIC="<devnet-only funded mnemonic>" \
ZNN_TEST_PASSWORD=test-password \
ZNN_TEST_RECIPIENT_ADDRESS="<recipient address>" \
dart run build_runner build --delete-conflicting-outputs

RUN_CHAIN_TESTS=true \
ZNN_TEST_NODE_URL=ws://127.0.0.1:35998 \
ZNN_TEST_MNEMONIC="<devnet-only funded mnemonic>" \
ZNN_TEST_PASSWORD=test-password \
ZNN_TEST_RECIPIENT_ADDRESS="<recipient address>" \
flutter test integration_test -d linux
```

Use the matching desktop target for the local platform when needed.

## Reliability Rules

- Keep blockchain tests few and focused.
- Do not run multiple tests concurrently from the same sender account unless nonce/account-chain ordering is handled carefully.
- Prefer unique recipient addresses per test.
- Assert balance deltas, not absolute balances, unless the chain is guaranteed fresh.
- Use polling with clear timeouts and diagnostics for node readiness and block confirmation.
- Keep devnet mnemonics isolated from real networks.
