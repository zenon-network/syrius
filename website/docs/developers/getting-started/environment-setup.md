---
sidebar_position: 1
title: Environment Setup
description: Install the pinned Flutter desktop toolchain, clone Syrius, configure Linux udev rules for Ledger, and run the wallet locally.
---

# Environment Setup

This guide walks through setting up a local development environment for building and running Syrius on **macOS**, **Windows**, or **Linux**.

## Toolchain Requirements

Syrius pins its Flutter SDK version in CI (`.github/actions/setup-flutter/action.yml`) to keep lockfile resolution, analyzer rules, and desktop runner builds deterministic:

- **Flutter SDK**: `3.47.6` (`stable` channel — pinned CI version)
- **Dart SDK**: Bundled with Flutter `3.47.6` (`pubspec.yaml` specifies `>=3.12.0`; the committed `pubspec.lock` expects `>=3.13.0 <4.0.0`)
- **Git**: Required for cloning, Git metadata generation (`tool/generate_git_metadata.dart`), and fetching Git-pinned dependencies (`znn_sdk_dart`, `znn_ledger_dart`, `fl_chart`)

Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install) and [Flutter desktop setup guide](https://docs.flutter.dev/desktop) to enable desktop builds for your platform.

### Platform-Specific Prerequisites

#### macOS

- **Xcode** (with Command Line Tools installed and license accepted)
- **CocoaPods** (required for macOS Flutter plugins)
- Optional (for DMG packaging): `brew install unzip create-dmg`

#### Windows

- **Visual Studio** with the **Desktop development with C++** workload
- **Microsoft Visual C++ Redistributable** (x64) for running release binaries

#### Linux (Ubuntu / Debian)

Install the native desktop build and runtime libraries used by CI (`.github/workflows/syrius_builder.yml`):

```bash
sudo apt update
sudo apt install -y \
  curl \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  unzip \
  xz-utils \
  zip \
  libnotify-dev \
  libayatana-appindicator3-dev \
  libsecret-1-dev \
  libjsoncpp-dev
```

:::info Headless Linux integration tests
If you plan to run desktop [Blockchain Integration Tests](/docs/developers/testing/blockchain-integration-tests) headlessly on Linux, also install `xvfb`.
:::

## Cloning and Installing Dependencies

Clone the repository and fetch Dart/Flutter packages:

```bash
git clone https://github.com/zenon-network/syrius.git
cd syrius
flutter pub get
```

Enable desktop support for your target platform if you have not already:

```bash
# Pick the command matching your OS
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
```

Verify your toolchain with `flutter doctor` and `flutter --version`.

## Running Locally

Launch Syrius directly on your host desktop target (`macos`, `windows`, or `linux`):

```bash
flutter run -d <macos|windows|linux>
```

### Running with Git Metadata

Inside Syrius, the **About / Info** card displays Git metadata from the commit used to build the binary (branch name, commit hash, commit message, commit date, and origin URL).

Generate `.dart_tool/git_metadata.json` before running and pass it via `--dart-define-from-file`:

```bash
dart run tool/generate_git_metadata.dart
flutter run -d <macos|windows|linux> --dart-define-from-file=.dart_tool/git_metadata.json
```

:::tip Optional during day-to-day dev
Running or building Syrius without generating `.dart_tool/git_metadata.json` will not break the wallet—the Git fields in the **About** card will simply remain empty.
:::

### IDE Run Configurations (`run_configurations/`)

The repository commits four JetBrains / Android Studio run configurations under `run_configurations/`:

| Configuration File | Name | Purpose |
| --- | --- | --- |
| `run_configurations/main-with-metadata.run.xml` | `main-with-metadata` | Runs `generate-git-metadata` as a pre-launch task, then launches `lib/main.dart` with `--dart-define-from-file=.dart_tool/git_metadata.json`. |
| `run_configurations/generate-git-metadata.run.xml` | `generate-git-metadata` | Runs `tool/generate_git_metadata.dart` to regenerate `.dart_tool/git_metadata.json`. |
| `run_configurations/devnet-alice.run.xml` | `devnet-alice` | Launches `lib/main.dart` with `--dart-define=ZNN_DATA_DIRECTORY=znn-alice` for an isolated local wallet/cache directory. |
| `run_configurations/devnet-bob.run.xml` | `devnet-bob` | Launches `lib/main.dart` with `--dart-define=ZNN_DATA_DIRECTORY=znn-bob` so you can run a second Syrius instance side-by-side (useful for testing P2P HTLC swaps against a local devnet). |

You can also use `ZNN_DATA_DIRECTORY` from the command line in any editor or terminal:

```bash
flutter run -d macos --dart-define=ZNN_DATA_DIRECTORY=znn-alice
```

When `ZNN_DATA_DIRECTORY` is set, `_configureZnnDataDirectories()` in `lib/main.dart` redirects wallet files, Hive caches, logs, and `HydratedBloc` storage into sibling folders under that isolated root directory instead of touching your default mainnet data directory.

## Linux `udev` Rules for Ledger Development

On Linux, unprivileged users cannot open USB HID Ledger devices via `hidapi` unless the Ledger `udev` rules from `udev/20-hw1.rules` are installed and your user belongs to the `plugdev` group (see `udev/README.md`):

```bash
sudo cp udev/*.rules /etc/udev/rules.d/ && \
sudo udevadm trigger && \
sudo udevadm control --reload-rules && \
sudo groupadd -f plugdev && \
sudo usermod -aG plugdev "$(whoami)"
```

Log out and log back in (or reboot) after updating group memberships so the `plugdev` group takes effect, then reconnect your Ledger device. For end-user Ledger troubleshooting, see the [Ledger Hardware Wallet guide](/docs/user-guide/hardware-and-nodes/ledger-hardware-wallet).
