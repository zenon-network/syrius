---
sidebar_position: 2
title: Building and Releases
description: Build macOS, Windows, and Linux release artifacts, inject Git metadata, manage embedded libznn blobs, and understand Syrius CI/CD workflows.
---

# Building and Releases

Syrius builds native release bundles for **macOS**, **Windows**, and **Linux**. This page covers local release builds, Git metadata injection, embedded native node blobs, community node refreshes, and every GitHub Actions workflow in `.github/workflows/`.

## Local Release Builds

### 1. Generate Git Metadata

Run `tool/generate_git_metadata.dart` to inspect the local Git repository and write `.dart_tool/git_metadata.json`:

```bash
dart run tool/generate_git_metadata.dart
```

The script emits five compile-time Dart defines consumed by the wallet's **About** card:

```json
{
  "SYRIUS_GIT_BRANCH_NAME": "develop",
  "SYRIUS_GIT_COMMIT_HASH": "<40-char SHA>",
  "SYRIUS_GIT_COMMIT_MESSAGE": "<commit subject>",
  "SYRIUS_GIT_COMMIT_DATE": "YYYY-MM-DD",
  "SYRIUS_GIT_ORIGIN_URL": "https://github.com/zenon-network/syrius"
}
```

In GitHub Actions, the script automatically prefers `GITHUB_HEAD_REF` / `GITHUB_REF_NAME` and `GITHUB_SERVER_URL`/`GITHUB_REPOSITORY` so detached-HEAD CI checkouts still report accurate branch and origin information.

### 2. Compile the Release Artifact

Pass `.dart_tool/git_metadata.json` to `flutter build`:

```bash
# macOS (builds build/macos/Build/Products/Release/s y r i u s.app)
flutter build macos --release --dart-define-from-file=.dart_tool/git_metadata.json

# Windows (builds build/windows/x64/runner/Release/)
flutter build windows --release --dart-define-from-file=.dart_tool/git_metadata.json

# Linux (builds build/linux/x64/release/bundle/)
flutter build linux --release --dart-define-from-file=.dart_tool/git_metadata.json
```

### 3. Packaging Artifacts (CI Parity)

The release pipeline packages platform builds into the following distributable archives:

| Platform | Output Archive | Packaging Tool |
| --- | --- | --- |
| **macOS** | `syrius-alphanet-macos-universal.dmg` | `create-dmg` using `macos/dmg/volume.icns` and `macos/dmg/background.png` |
| **Windows** | `syrius-alphanet-windows-amd64.zip` | `Compress-Archive` over `build\windows\x64\runner\Release\*` |
| **Linux** | `syrius-alphanet-linux-amd64.zip` | `zip -r` over `build/linux/x64/release/bundle/*` |

When publishing a GitHub Release on `v*` tags, CI also computes and verifies `SHA256CHECKSUMS.txt` across all three archives using `sha256sum`.

## Embedded Node Native Blobs (`libznn`)

Syrius ships precompiled `go-zenon` embedded node shared libraries directly in the repository under `lib/embedded_node/blobs/`:

- `lib/embedded_node/blobs/libznn.dylib` — macOS (universal)
- `lib/embedded_node/blobs/libznn.dll` — Windows (amd64)
- `lib/embedded_node/blobs/libznn.so` — Linux (amd64)
- `lib/embedded_node/blobs/libznn.manifest.json` — Provenance manifest pinning the upstream `zenon-network/go-zenon` release tag, commit SHA, `SHA256CHECKSUMS.txt` digest, archive SHA-256, and extracted binary SHA-256 for every platform blob

:::caution Do not manually edit or move `libznn` blobs
`lib/embedded_node/embedded_node.dart` searches known relative and bundle paths for `libznn.{dylib,dll,so}` at runtime, and `.github/workflows/pr-validation.yml` runs `.github/scripts/verify_libznn_manifest.py` on every pull request to enforce that the committed blobs match `libznn.manifest.json`. Use the `syrius_lib_updater.yml` workflow whenever updating the embedded node.
:::

## Community Nodes Refresh (`assets/community-nodes.json`)

At startup, `_loadDefaultCommunityNodes()` in `lib/main.dart` reads `assets/community-nodes.json` and validates each node URL with `InputValidators.node`.

During CI builds in `.github/workflows/syrius_builder.yml`, every platform job checks out [`zenon-network/zenon-node-database`](https://github.com/zenon-network/zenon-node-database) (`main` branch) and copies `rpc-nodes-mainnet.json` over `assets/community-nodes.json` right before building.

:::info Debugging community node lists
If the list of default remote nodes in a release build differs from your local working tree, check [`zenon-network/zenon-node-database`](https://github.com/zenon-network/zenon-node-database) first—CI refreshes `assets/community-nodes.json` from upstream during every build.
:::

## CI/CD Workflows (`.github/workflows/`)

All Flutter workflows share the composite action `.github/actions/setup-flutter/action.yml`, which installs Flutter `3.47.6` (`stable`) with dependency caching enabled.

| Workflow File | Name | Triggers | What It Does |
| --- | --- | --- | --- |
| `.github/workflows/pr-validation.yml` | **PR Fast Validation** | `pull_request` (`develop`, `master`), `workflow_dispatch` | Runs Python unit tests for `.github/scripts/`, verifies `libznn.manifest.json` provenance, installs deps with `flutter pub get --enforce-lockfile`, runs `flutter analyze --no-pub`, runs `flutter test --no-pub test --exclude-tags chain`, and ensures committed codegen outputs are fresh (`dart run build_runner build && dart format integration_test && git diff --exit-code`). |
| `.github/workflows/syrius_builder.yml` | **Build and release syrius** | `pull_request` (`develop`), `push` (`master` and `v*` tags), `workflow_dispatch` | Refreshes `assets/community-nodes.json`, generates Git metadata, builds and packages macOS (`macos-26`), Windows (`windows-latest`), and Linux (`ubuntu-24.04`) release artifacts, and—on `v*` tags—generates `SHA256CHECKSUMS.txt` and publishes a GitHub Release (`prerelease: true` when the tag contains `-`). |
| `.github/workflows/syrius_lib_updater.yml` | **Update embedded libznn binaries** | Weekly schedule (`0 6 * * 1`, Mondays 06:00 UTC, upstream only) & `workflow_dispatch` | Fetches release metadata and `SHA256CHECKSUMS.txt` from `zenon-network/go-zenon`, verifies archive and extracted SHA-256 digests, stages updated `libznn.{so,dylib,dll}` and `libznn.manifest.json`, and opens/updates a PR against `develop` or `master` (supports `tag`, `dry_run`, and `allow_downgrade` inputs). |
| `.github/workflows/blockchain-integration-tests.yml` | **Blockchain Integration Tests** | `pull_request` (`develop`), `workflow_dispatch` | Checks out the pinned Docker devnet (`digitalSloth/go-zenon`), runs `make devnet-up`, waits for chain readiness via `./scripts/wait-for-devnet.sh`, and executes every `integration_test/features/*_test.dart` suite headlessly on Linux using `xvfb-run -a flutter test ... -d linux --tags chain`. |
| `.github/workflows/deploy-docs.yml` | **Deploy Documentation** | `push` & `pull_request` (`master`, `develop` on `website/**` or `.github/workflows/deploy-docs.yml`), `workflow_dispatch` | Sets up Node.js `22` on `ubuntu-24.04`, derives `DOCS_URL` / `DOCS_BASE_URL` for forks, upstream, or custom domains, runs `npm ci`, `npm run typecheck`, and `npm run build` in `website/`, and deploys `website/build` to GitHub Pages on `push` / `workflow_dispatch`. |

:::tip Maintainer note on updater PRs
Pull requests opened automatically by `syrius_lib_updater.yml` using `GITHUB_TOKEN` require a maintainer with write access to click **Approve workflows to run** in the GitHub PR checks box before `pull_request` workflows execute.
:::
