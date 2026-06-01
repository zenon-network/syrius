# AGENTS

## Scope and stack
- This repo is a single Flutter desktop wallet app (not a monorepo); main package config is `pubspec.yaml`.
- Supported runtime targets here are desktop (`macos`, `windows`, `linux`); CI builds only these three.
- Core startup/DI wiring lives in `lib/main.dart` (and a dev entrypoint in `lib/main_dev.dart` used by `run_configurations/dev.run.xml`).

## Canonical commands
- Install deps: `flutter pub get`
- Run locally: `flutter run -d <macos|windows|linux>`
- Build desktop artifact: `flutter build <macos|windows|linux> --release`
- Run tests: `flutter test`
- Run one test file: `flutter test test/path/to/file_test.dart`
- Static analysis: `flutter analyze`

## Codegen and generated files
- The app uses generated Dart (`*.g.dart`) from `json_annotation`/`json_serializable`; regenerate with `dart run build_runner build --delete-conflicting-outputs` after model/annotation changes.
- `analysis_options.yaml` excludes `**/*.g.dart`; do not manually lint-fix generated outputs.
- Localization is generated (`flutter.generate: true`, `l10n.yaml`); treat `lib/l10n/app_localizations*.dart` as generated artifacts.

## Repo-specific gotchas
- `pubspec.yaml` overrides upstream packages: `reown_core` is patched from `patched_packages/reown_core-1.3.8`, and `znn_sdk_dart` is pinned to a fork/branch (`maznnwell/...@refactor`). Avoid "upgrading" these without intent.
- Embedded node native libs are committed under `lib/embedded_node/blobs/` and loaded dynamically by `lib/embedded_node/embedded_node.dart`; do not delete/move these files.
- CI refreshes `assets/community-nodes.json` from `zenon-network/zenon-node-database` during builds; if node list behavior changes, check that upstream source first.
- On Linux with Ledger/HID usage, udev rules from `udev/` are required (`udev/README.md`).
- Currently, the repo is going through a rearchitecture phase: from an MVVM architecture, using stacked, to a classical BLoC feature-based architecture.

## Architecture
- The architecture that should be followed is a BLoC feature-based architecture
- All feature should be added to rearchitecture/features; and there you will find other features that follow the specified architecture
