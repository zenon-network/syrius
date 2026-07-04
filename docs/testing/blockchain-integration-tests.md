# Blockchain Integration Tests

## Purpose

Blockchain integration tests validate wallet behavior against a real devnet node. They should cover the full wallet path whenever practical: user input in the Flutter UI, BLoC/event handling, wallet signing, node submission, and blockchain state assertions.

The purpose of these tests is not visual UI coverage. The UI is used as the entry point so the test exercises the same values and actions that a user sees and performs. For fund-moving actions, prefer driving the real widget fields/buttons over calling BLoCs or SDK methods directly.

For the initial scope, add a component-level widget-driven send transaction test that pumps the Send widget with real devnet wallet state, enters a ZNN amount and recipient address, confirms the send action, and verifies that the devnet blockchain reflects the same amount, token, and recipient.

## Step-by-Step Setup

1. Make sure the Docker devnet node can start locally with one command and exposes its WebSocket RPC port.
2. Configure the devnet genesis or startup script so one deterministic test wallet starts with enough ZNN.
3. Choose a devnet-only sender mnemonic and recipient address for the test.
4. Add `bdd_widget_test` and `integration_test` as dev dependencies.
5. Configure `build.yaml` so `bdd_widget_test` generates tests from files under `integration_test/`.
6. Add stable keys to the Send UI fields and button so the generated test steps can reliably find them.
7. Add `integration_test/features/send_transaction.feature` with the Gherkin send scenario.
8. Generate the Dart test and step files with `dart run build_runner build --delete-conflicting-outputs`.
9. Implement the generated steps so they prepare devnet wallet state, pump the Send widget, type the recipient and amount into the Send UI, confirm the dialog, and wait for the published account-block hash.
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

A safe first fork version can run manually and on PRs targeting the fork's `develop` branch:

```yaml
on:
  workflow_dispatch:
  pull_request:
    branches:
      - develop
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

The first security-oriented scenario should prove that the data sent from the wallet matches the data found on-chain.

For the Send flow, capture the account-block hash returned by the send action, then fetch that exact block with `zenon.ledger.getAccountBlockByHash(hash)` and assert:

- a block exists for the returned hash
- the fetched block hash equals the returned hash
- the recipient equals the address typed into the UI
- the amount equals the amount typed into the UI
- the token standard is ZNN

Use randomized recipient addresses and amounts where practical, so malicious code cannot easily special-case one hard-coded test value.

## Test Strategy

- Keep unit and BLoC tests mocked and fast under `test/`.
- Put blockchain tests under `integration_test/`.
- Start with a component-level integration test that pumps the real Send widget, but still uses the real devnet, wallet signing path, and blockchain assertions.
- Drive the Send UI with Flutter test APIs instead of calling SDK send methods directly.
- Use the real `SendTransactionBloc` and `AccountBlockUtils` path where possible.
- Query the devnet node only for setup and final assertions.
- Poll for blockchain state because account blocks and momentum confirmation are eventually consistent.
- Add a later full app-journey test for `splash -> locked screen -> password unlock -> dashboard -> Send tab` after the component-level Send test is stable.

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

## Chain Test Tag

Use the Gherkin `@chain` tag on scenarios that require a real devnet node or validate blockchain state.

`bdd_widget_test` converts Gherkin tags into Dart test metadata. For example, this feature tag:

```gherkin
@chain
Feature: Send ZNN on devnet
```

generates Dart test metadata like:

```dart
@Tags(['chain'])
```

The custom `chain` tag is declared in `dart_test.yaml` so Dart's `package:test` runner, and therefore `flutter test`, recognizes it. This keeps devnet-dependent tests distinguishable from fast mocked unit/widget tests.

Run only chain tests with:

```bash
flutter test integration_test --tags chain
```

Run tests while excluding chain tests with:

```bash
flutter test --exclude-tags chain
```

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

The current devnet reference is the Docker devnet work from `digitalSloth/go-zenon`:

```text
https://github.com/digitalSloth/go-zenon/tree/feature/docker-devnet
```

During local development, this can be started manually from Docker Desktop. For CI, the same devnet setup should eventually be published or made available as a Docker image that GitHub Actions can run as a service container.

The Docker devnet should provide:

- An HTTP RPC endpoint exposed to the runner, configured as `ZNN_TEST_HTTP_URL`.
- A WebSocket RPC endpoint exposed to the runner, configured as `ZNN_TEST_NODE_URL`.
- A clean chain state for each CI job.
- A deterministic funded test wallet or deterministic funded sender address in genesis.
- A deterministic recipient address or a way for tests to derive one.
- Non-interactive startup and shutdown.
- A reliable readiness condition, such as responding to `ledger.getFrontierMomentum` or `stats.syncInfo`.

## Environment Variables

Use environment variables so the same test can run locally and in CI:

```text
ZNN_TEST_HTTP_URL=http://127.0.0.1:35997
ZNN_TEST_NODE_URL=ws://127.0.0.1:35998
ZNN_TEST_MNEMONIC="abstract affair idle position alien fluid board ordinary exist afraid chapter wood wood guide sun walnut crew perfect place firm poverty model side million"
ZNN_TEST_PASSWORD=devnet
ZNN_TEST_SENDER_INDEX=3
ZNN_TEST_RECIPIENT_INDEX=8
```

These values come from the `digitalSloth/go-zenon` Docker devnet README. They are devnet-only and must never be reused on mainnet.

## Send Transaction Test Flow

The first integration test should verify that an amount typed into the wallet UI is the amount published on-chain.

Recommended flow:

1. Run the test through the `chain` tag so non-devnet integration tests can be included or excluded separately.
2. Connect the test world to `ZNN_TEST_NODE_URL` and verify devnet chain ID `69`.
3. Derive the sender and recipient from the devnet mnemonic and configured indices.
4. Configure the in-memory wallet state required by `AccountBlockUtils` while preserving the sender account index.
5. Fetch the sender balance.
6. Pump the real Send widget with real BLoC wiring and devnet account info.
7. Enter the recipient address and test ZNN amount.
8. Tap the Send button and confirm the dialog.
9. Wait for `SendTransactionBloc` to report success.
10. Capture the account-block hash returned by `SendTransactionBloc`.
11. Poll `zenon.ledger.getAccountBlockByHash(hash)` until the send block is confirmed.
12. Assert that the fetched block hash, recipient, amount, and token standard match the UI input.

For the first version, prefer asserting the published send block and the receiver's unreceived transaction. Receiver balance assertions require a receive block, so they test a broader flow and should be added separately.

## Stable Widget Selectors

Before adding the integration test, add stable keys to the Send UI so tests do not depend on localized strings or widget ordering:

```dart
const Key('wallet_password_field')
const Key('wallet_unlock_button')
const Key('dashboard_screen')
const Key('send_tab')
const Key('send_recipient_field')
const Key('send_amount_field')
const Key('send_submit_button')
```

These keys should be attached to the real app flow: locked wallet screen, Dashboard, Send tab, recipient field, amount field, and send button.

## GitHub Actions Shape

Use separate jobs for fast validation, desktop builds, and blockchain integration tests.

```yaml
on:
  workflow_dispatch:
  pull_request:
    branches:
      - develop

env:
  FLUTTER_VERSION: "3.44.0"

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
    runs-on: ubuntu-24.04
    env:
      ZNN_TEST_HTTP_URL: http://127.0.0.1:35997
      ZNN_TEST_NODE_URL: ws://127.0.0.1:35998
      ZNN_TEST_MNEMONIC: "abstract affair idle position alien fluid board ordinary exist afraid chapter wood wood guide sun walnut crew perfect place firm poverty model side million"
      ZNN_TEST_PASSWORD: devnet
      ZNN_TEST_SENDER_INDEX: "3"
      ZNN_TEST_RECIPIENT_INDEX: "8"
    steps:
      - name: Checkout syrius
        uses: actions/checkout@v4
      - name: Checkout devnet
        uses: actions/checkout@v4
        with:
          repository: digitalSloth/go-zenon
          ref: feature/docker-devnet
          path: go-zenon-devnet
      - name: Start devnet
        working-directory: go-zenon-devnet
        run: make devnet-up
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{env.FLUTTER_VERSION}}
          channel: "stable"
      - name: Install Linux desktop dependencies
        run: |
          sudo apt update
          sudo apt update
          sudo apt install -y libsecret-1-dev libjsoncpp-dev
          sudo apt install -y curl clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev unzip xz-utils zip libnotify-dev libayatana-appindicator3-dev xvfb
      - name: Set permissions
        run: |
          sudo chmod -R 777 linux/
      - name: Check flutter version
        run: |
          which flutter
          flutter --version
      - run: flutter config --enable-linux-desktop
      - run: flutter pub get
      - run: ./scripts/wait-for-devnet.sh
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: xvfb-run -a flutter test integration_test -d linux --tags chain
      - name: Dump devnet logs
        if: failure()
        working-directory: go-zenon-devnet
        run: docker compose logs --no-color
      - name: Stop devnet
        if: always()
        working-directory: go-zenon-devnet
        run: make devnet-down || true
```

The blockchain integration job starts the Docker Compose devnet in the same GitHub Actions job that runs the tests. This is required because GitHub Actions jobs are isolated from each other, and the test process needs to connect to the devnet through `ws://127.0.0.1:35998` on the same runner.

The devnet checkout currently tracks `digitalSloth/go-zenon@feature/docker-devnet`. Once the setup is stable, pin this checkout to a commit SHA or move the devnet source to the canonical upstream location.

## Local Run Shape

Run the Docker Compose devnet locally, then wait for the RPC endpoint and run:

```bash
ZNN_TEST_HTTP_URL=http://127.0.0.1:35997 \
ZNN_TEST_NODE_URL=ws://127.0.0.1:35998 \
ZNN_TEST_MNEMONIC="abstract affair idle position alien fluid board ordinary exist afraid chapter wood wood guide sun walnut crew perfect place firm poverty model side million" \
ZNN_TEST_PASSWORD=devnet \
ZNN_TEST_SENDER_INDEX=3 \
ZNN_TEST_RECIPIENT_INDEX=8 \
./scripts/wait-for-devnet.sh

ZNN_TEST_HTTP_URL=http://127.0.0.1:35997 \
ZNN_TEST_NODE_URL=ws://127.0.0.1:35998 \
ZNN_TEST_MNEMONIC="abstract affair idle position alien fluid board ordinary exist afraid chapter wood wood guide sun walnut crew perfect place firm poverty model side million" \
ZNN_TEST_PASSWORD=devnet \
ZNN_TEST_SENDER_INDEX=3 \
ZNN_TEST_RECIPIENT_INDEX=8 \
dart run build_runner build --delete-conflicting-outputs

ZNN_TEST_HTTP_URL=http://127.0.0.1:35997 \
ZNN_TEST_NODE_URL=ws://127.0.0.1:35998 \
ZNN_TEST_MNEMONIC="abstract affair idle position alien fluid board ordinary exist afraid chapter wood wood guide sun walnut crew perfect place firm poverty model side million" \
ZNN_TEST_PASSWORD=devnet \
ZNN_TEST_SENDER_INDEX=3 \
ZNN_TEST_RECIPIENT_INDEX=8 \
flutter test integration_test -d linux --tags chain
```

Use the matching desktop target for the local platform when needed.

## Reliability Rules

- Keep blockchain tests few and focused.
- Do not run multiple tests concurrently from the same sender account unless nonce/account-chain ordering is handled carefully.
- Prefer unique recipient addresses per test.
- Assert balance deltas, not absolute balances, unless the chain is guaranteed fresh.
- Use polling with clear timeouts and diagnostics for node readiness and block confirmation.
- Keep devnet mnemonics isolated from real networks.
