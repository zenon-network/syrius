---
sidebar_position: 1
title: Contributing Guide
description: Open contributor model, Zenon Code of Conduct, pull request checklist, MIT licensing and attribution headers, and contributing to Syrius documentation.
---

# Contributing to Syrius

The Zenon project operates an **open contributor model** where anyone is welcome to contribute through peer review, testing, bug reports, patches, and documentation improvements. New contributors are always welcome.

## Project Governance & Open Contributor Model

Adapted from `CONTRIBUTING.md`:

- There is no privileged closed circle of "Zenon developers"—open-source collaboration naturally revolves around a meritocracy where contributors earn trust from the developer community over time.
- For practical day-to-day coordination, repository **maintainers** review and merge pull requests, and a **lead maintainer** oversees the release cycle, overall merging, moderation, and appointment of maintainers.

## Code of Conduct

This repository follows the Zenon Code of Conduct (`CODE_OF_CONDUCT.md`). All contributors are expected to act professionally and respectfully so our spaces stay safe and dignified:

- Respect people, their identities, their culture, and their work.
- Be kind, courteous, and welcoming.
- Listen—consider and acknowledge others' points before responding.

### Conflict Resolution

When contributors disagree on a patch or design direction:

- Communicate directly to understand each other's viewpoints and seek a design that addresses everyone's concerns.
- If you cannot reach consensus, ask a more senior member of the team for advice.
- Avoid **agreement by attrition** (repeating an argument until others give up) and avoid **agreement by compromise** (merging two good ideas into one mediocre result). Aim for a solution that participants agree is better than all competing proposals.

### Asking Questions

It is always okay to ask questions—Syrius spans Flutter desktop UI, native FFI, embedded `go-zenon`, encrypted SQLite, and WalletConnect. Once you find an answer, **document it in the first place you looked** so the next contributor ramps up faster.

## Pull Request Checklist

Before opening a pull request (typically targeting `develop`), run through every check enforced by `.github/workflows/pr-validation.yml` and `AGENTS.md`:

1. **Dependencies & Lockfile**
   - Run `flutter pub get --enforce-lockfile` (or `flutter pub get` if intentionally updating packages).
   - Do not modify the `znn_sdk_dart` tag (`v1.1.0`), its `dependency_overrides` block, or `hooks.user_defines.sqlite3.source: sqlite3mc` in `pubspec.yaml` without clear intent.
2. **Architecture & Code Style**
   - Place new or refactored features under `lib/rearchitecture/features/` following the [BLoC Rearchitecture Guide](/docs/developers/architecture/bloc-rearchitecture).
   - Preserve Git history by moving/renaming existing files when refactoring legacy widgets or BLoCs.
   - Prefix widget-returning helper methods inside widgets with `_build*`, keep internal classes and fields private, and write explicit types everywhere (`always_specify_types: true`).
3. **Localization**
   - Replace hard-coded user-facing strings with content-based keys in `lib/l10n/app_en.arb` accessed via `context.l10n`.
   - Never manually edit `lib/l10n/app_localizations*.dart`. See [Localization, Theming, and Codegen](/docs/developers/architecture/localization-and-theming).
4. **Code Generation**
   - After modifying annotated models, Hive adapters, Drift tables, or `.feature` files, run:
     ```bash
     dart run build_runner build --delete-conflicting-outputs
     dart format integration_test
     ```
   - Commit the regenerated outputs and never hand-edit `*.g.dart` files.
5. **Static Analysis & Unit Tests**
   - Ensure zero analyzer issues:
     ```bash
     flutter analyze
     ```
   - Ensure all unit/widget tests pass and include BLoC/Cubit tests for every new or refactored feature:
     ```bash
     flutter test test --exclude-tags chain
     ```
6. **Embedded Node Integrity**
   - Do not move, delete, or manually overwrite `lib/embedded_node/blobs/*`. If touching CI scripts or manifests, verify:
     ```bash
     python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v
     python3 .github/scripts/verify_libznn_manifest.py --repo-root .
     ```
7. **On-Chain Flows (When Applicable)**
   - If your change modifies fund-moving UI or embedded contract flows, add or run the relevant `@chain` suite described in [Blockchain Integration Tests](/docs/developers/testing/blockchain-integration-tests).

## Licensing & Attribution

Syrius is distributed under **The MIT License (MIT)** (`LICENSE`, `Copyright (c) 2025 The Zenon developers`).

- By contributing to this repository, you agree to license your work under the **MIT license** unless specified otherwise at the top of the file itself.
- Any contributed file or code where you are **not** the original author **must** retain its license header including the original author(s) and source.

## Contributing to Documentation (`website/`)

This documentation site lives inside `website/` and is built with **Docusaurus v3** (TypeScript).

### Directory Ownership

- **`website/docs/user-guide/`** — End-user wallet guides written in plain, non-technical language (see [User Guide](/docs/user-guide/intro)).
- **`website/docs/developers/`** — Contributor and architecture documentation (this section).
- **`website/docusaurus.config.ts`** & **`website/sidebars.ts`** — Site metadata, navigation, theme config, and autogenerated sidebar definitions.

### Running & Validating Docs Locally

Requires Node.js and npm:

```bash
cd website
npm install

# Start a hot-reloading local dev server
npm start

# Type-check TypeScript and run a strict production build
npm run typecheck
npm run build
```

:::tip Documentation conventions
- Every docs subfolder must include a `_category_.json` file with `label`, `position`, and a `generated-index` link, and every Markdown page should declare `sidebar_position` in its frontmatter.
- `docusaurus.config.ts` enforces strict link checking (`onBrokenLinks: 'throw'`), so `npm run build` immediately catches any broken internal or Markdown links.
- When adding Mermaid diagrams (` ```mermaid `), quote node labels containing parentheses, slashes, or special characters (for example `Node["Label (Detail)"]`) and avoid HTML tags inside labels.
:::
