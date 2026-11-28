---
sidebar_position: 1
title: Developer Overview
description: Technical overview of the Syrius cross-platform Flutter desktop wallet codebase, technology stack, and repository layout.
---

# Developer Overview

**Syrius** (`zenon_syrius_wallet_flutter`) is the official cross-platform, non-custodial desktop wallet for **Zenon Network (Network of Momentum Phase 1 — Alphanet)**. This repository is a single Flutter desktop application (not a monorepo) targeting **macOS**, **Windows**, and **Linux**.

Looking for end-user wallet instructions instead? Head over to the [User Guide](/docs/user-guide/intro).

## Technology Stack

| Layer | Technology | Repository / Package |
| --- | --- | --- |
| **Framework & Runtime** | Flutter `3.47.6` (CI-pinned) / Dart `>=3.12.0` (`>=3.13.0 <4.0.0` lockfile) | `pubspec.yaml`, `.github/actions/setup-flutter/action.yml` |
| **Desktop Targets** | macOS (Universal DMG), Windows (x64), Linux (x64) | `macos/`, `windows/`, `linux/` |
| **Zenon Protocol SDK** | `znn_sdk_dart` (pinned to `v1.1.0`) | [`zenon-network/znn_sdk_dart`](https://github.com/zenon-network/znn_sdk_dart) |
| **Hardware Wallet SDK** | `znn_ledger_dart` (pinned to `v1.0.0`) | [`zenon-network/znn_ledger_dart`](https://github.com/zenon-network/znn_ledger_dart) |
| **State Management & DI** | `flutter_bloc`, `bloc`, `hydrated_bloc`, `get_it`, `provider` | `lib/main.dart`, `lib/rearchitecture/features/` |
| **Local Persistence** | `hive_ce` (preferences, notifications, cache) & `drift` + `sqlite3` (`sqlite3mc` SQLCipher) for encrypted HTLC P2P swaps | `lib/hive/`, `lib/rearchitecture/features/p2p_swaps/data/`, `drift_schemas/` |
| **dApp Connectivity** | Reown / WalletConnect v2 (`reown_walletkit`, `reown_core`) | `lib/services/web3wallet_service.dart`, `lib/services/nom_service.dart` |
| **Localization & Linting** | Flutter `gen-l10n` (`lib/l10n/app_en.arb`), `very_good_analysis` | `l10n.yaml`, `analysis_options.yaml` |
| **Code Generation** | `build_runner`, `json_serializable`, `freezed`, `hive_ce_generator`, `drift_dev`, `bdd_widget_test` | `build.yaml` |

### Native FFI Libraries

Syrius relies on Dart Foreign Function Interface (`dart:ffi`) bindings for cryptographic primitives, feeless PoW generation, embedded node execution, and hardware wallet communication:

- **Embedded Full Node (`libznn`)** — Prebuilt `go-zenon` shared libraries (`libznn.dylib`, `libznn.dll`, `libznn.so`) committed under `lib/embedded_node/blobs/` alongside a provenance manifest (`libznn.manifest.json`) and loaded dynamically by `lib/embedded_node/embedded_node.dart`.
- **Key Derivation (Argon2)** — [`argon2_ffi`](https://github.com/zenon-network/argon2_ffi) (via `znn_sdk_dart`) for keystore encryption and decryption.
- **Proof-of-Work Links** — [`znn-pow-links-cpp`](https://github.com/zenon-network/znn-pow-links-cpp) (via `znn_sdk_dart`) for generating feeless transaction PoW when Plasma is unavailable.
- **Ledger Hardware Wallet Transport** — [`ledger_ffi_rs`](https://github.com/zenon-network/ledger_ffi_rs) (via `znn_ledger_dart`) for HID communication with Ledger devices.

:::warning Native library blobs and SDK pins
Do **not** delete or move the files under `lib/embedded_node/blobs/`, and avoid changing the `znn_sdk_dart` tag (`v1.1.0`) or its matching `dependency_overrides` block in `pubspec.yaml` without explicit intent. See [System Architecture](/docs/developers/architecture/overview) for details.
:::

## Repository Layout

```text
syrius/
├── lib/
│   ├── main.dart                     # App startup, DI (get_it), HydratedBloc, Hive, window & tray setup
│   ├── embedded_node/                # Dynamic FFI loader (embedded_node.dart) + prebuilt libznn blobs
│   ├── hive/                         # Hive CE adapter specs & generated registrar
│   ├── l10n/                         # Source ARB (app_en.arb) + generated AppLocalizations
│   ├── model/                        # Shared models, WalletNotification, BlockData
│   ├── rearchitecture/
│   │   ├── features/                 # 115 feature-based BLoC/Cubit modules (target architecture)
│   │   └── utils/                    # FetchBloc, InfiniteListBloc, theming tokens, l10n resolver, widgets
│   ├── screens/                      # Top-level route screens
│   ├── services/                     # WalletConnect/Reown, NoMService, SharedPrefsService, secure store
│   ├── utils/                        # Constants, AppTheme, AppColors, NodeUtils, WalletFile helpers
│   └── widgets/                      # Shared legacy & reusable widgets
├── test/                             # Fast mocked unit, BLoC/Cubit, repository, and widget tests
├── integration_test/                 # Gherkin .feature specs, generated *_test.dart, steps & devnet helpers
├── drift_schemas/                    # Committed Drift schema snapshots (htlc_swaps_database)
├── tool/                             # Build utilities (generate_git_metadata.dart)
├── scripts/                          # Devnet readiness helper (wait-for-devnet.sh)
├── run_configurations/               # Android Studio / IntelliJ run configs (main-with-metadata, devnet-alice/bob)
├── udev/                             # Linux HID udev rules for Ledger hardware wallets (20-hw1.rules)
├── assets/                           # SVGs, images, Lottie animations, and community-nodes.json
├── macos/ windows/ linux/            # Platform-specific desktop runner projects
├── website/                          # This Docusaurus v3 documentation portal
└── .github/                          # CI/CD workflows, reusable setup-flutter action, and updater scripts
```

## Canonical Commands

```bash
# Install dependencies
flutter pub get

# Run locally on your desktop OS (macos, windows, or linux)
flutter run -d <macos|windows|linux>

# Static analysis
flutter analyze

# Run unit and widget tests (excluding devnet chain tests)
flutter test test --exclude-tags chain

# Regenerate JSON, Freezed, Hive, Drift, and BDD outputs
dart run build_runner build --delete-conflicting-outputs

# Build a release artifact
flutter build <macos|windows|linux> --release
```

## Where to Go Next

- **[Environment Setup](/docs/developers/getting-started/environment-setup)** — Install Flutter `3.47.6`, configure Linux `udev` rules, and launch Syrius with IDE run configurations.
- **[Building & Releases](/docs/developers/getting-started/building-and-releases)** — Generate Git metadata, package desktop release artifacts, and understand all five GitHub Actions workflows.
- **[System Architecture](/docs/developers/architecture/overview)** — Dive into startup DI, embedded node lifecycle, Hive/Drift persistence, and Reown WalletConnect wiring.
- **[BLoC Rearchitecture Guide](/docs/developers/architecture/bloc-rearchitecture)** — Follow Syrius's conventions for building and refactoring feature modules under `lib/rearchitecture/features/`.
- **[Localization, Theming, and Codegen](/docs/developers/architecture/localization-and-theming)** — Reference ARB key naming rules, `build_runner` generators, and static analysis settings.
- **[Branding & Design System](/docs/developers/architecture/branding-and-design-system)** — Explore official logo rules, all 32 dark/light `SyriusThemeTokens` with live swatches, signature gradients, typography, and reusable redesign UI primitives.
- **[P2P Swaps HTLC Protocol](/docs/developers/architecture/p2p-swaps-protocol)** — Read the full technical HTLC specification, timing constants, and auto-unlock architecture.
- **[Testing](/docs/developers/testing/unit-and-widget-tests)** & **[Blockchain Integration Tests](/docs/developers/testing/blockchain-integration-tests)** — Write mocked BLoC tests and Dockerized devnet BDD integration tests.
- **[Contributing Guide](/docs/developers/contributing/contributing-guide)** — Review the PR checklist, licensing rules, and documentation contribution workflow.
