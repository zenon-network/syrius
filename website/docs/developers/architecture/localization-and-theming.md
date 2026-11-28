---
sidebar_position: 4
title: Localization, Theming, and Codegen
description: Developer reference for Syrius's ARB localization system, SyriusThemeTokens light/dark theming, build_runner code generation, and analyzer rules.
---

# Localization, Theming, and Codegen

This page documents how Syrius manages user-facing strings, light/dark semantic design tokens, `build_runner` code generation, and Dart static analysis rules.

## Localization (`l10n`)

Syrius uses Flutter's built-in `gen-l10n` pipeline (`flutter.generate: true` in `pubspec.yaml`), configured in `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### Source vs. Generated Files

- **Source of truth**: `lib/l10n/app_en.arb`
- **Generated artifacts (do not edit manually)**: `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_en.dart`

Regenerate localization files by running `flutter gen-l10n` (or any `flutter pub get` / `flutter build` / `flutter test` invocation).

### Accessing Localized Strings

#### Inside Widgets (`context.l10n`)

Use the `BuildContextExtension` getter defined in `lib/rearchitecture/utils/extensions/buildcontext_extension.dart`:

```dart
Text(context.l10n.pillars)
Text(context.l10n.pillarsListDescription(kZnnCoin.symbol))
```

#### Outside Widgets (`resolveAppLocalizations`)

Background services and BLoCs that do not hold a `BuildContext` (such as `HtlcSwapAutoUnlockService`) use `resolveAppLocalizations()` from `lib/rearchitecture/utils/l10n/app_localizations_resolver.dart`. It resolves `AppLocalizations` in order: explicit `locale` → mounted `context` / `globalNavigatorKey` → `PlatformDispatcher.instance.locale` → first supported locale fallback.

### Key Naming & Reuse Rules

Localizing all user-facing strings is **mandatory** whenever creating or refactoring a widget. Follow these naming rules strictly:

1. **Name keys after the string's content**, not the feature, widget, screen, or visual role:
   - Good: `"enterNomAddress": "Enter NoM Address"`
   - Avoid: `"p2pSwapAddressHint": "Enter NoM address"`
2. **Keep keys simple, reusable, and concise** — Derive longer keys directly from the phrase itself, aiming for no more than **5–7 words**.
3. **Reuse existing keys thoughtfully** — Reuse an existing key only when both its content and meaning match **and** its name complies with these rules.
4. **Fix noncompliant keys instead of preserving them** — If a matching existing key violates these naming rules, rename it in `lib/l10n/app_en.arb`, update all call sites across the repo, and reuse the corrected key.

For parameterized or pluralized strings, include `@<key>` metadata with `description` and `placeholders` (matching `lib/l10n/app_en.arb`):

```json
{
  "addAddressesCount": "{count, plural, =1{Add 1 address} other{Add {count} addresses}}",
  "@addAddressesCount": {
    "description": "Action label for adding one or more wallet addresses.",
    "placeholders": {
      "count": {
        "type": "int",
        "example": "1"
      }
    }
  }
}
```

## Theming (`SyriusThemeTokens` & `AppTheme`)

:::tip Full Branding & Design System Reference
For official logo usage, live dark/light color swatches across all **32** `SyriusThemeTokens`, signature gradients, typography & tabular numeral rules, WCAG AA+ contrast guidance, and reusable redesign widget primitives (`lib/rearchitecture/utils/widgets/redesign/`), see the **[Branding & Design System](/docs/developers/architecture/branding-and-design-system)** guide.
:::

Syrius defaults to **dark mode** (`kDefaultThemeMode = ThemeMode.dark` in `lib/utils/constants.dart`) and supports switching between light, dark, and system themes via `AppThemeNotifier` (`lib/main.dart`).

### Semantic Design Tokens (`SyriusThemeTokens`)

`SyriusThemeTokens` (`lib/rearchitecture/utils/theming/syrius_theme_tokens.dart`) is a Flutter `ThemeExtension<SyriusThemeTokens>` providing matched `SyriusThemeTokens.dark` and `SyriusThemeTokens.light` palettes, registered on both `AppTheme` (`lib/utils/app_theme.dart`) and the Material 3 redesign themes (`newLightTheme` / `newDarkTheme` in `lib/rearchitecture/utils/theming/new_app_themes.dart`).

Access tokens in any widget via `BuildContextExtension`:

```dart
final SyriusThemeTokens tokens = context.syriusTheme;

Container(
  decoration: BoxDecoration(
    color: tokens.surface,
    border: Border.all(color: tokens.border),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    address.toString(),
    style: tokens.monoStyle(color: tokens.znnGreen),
  ),
)
```

Key semantic tokens and helpers:

| Token / Helper | Dark Value | Light Value | Usage |
| --- | --- | --- | --- |
| `shellBackground` | `#1B1C1B` | `#EAEAEA` | Outer window, sidebar rail, canvas backdrop |
| `surface` | `#262726` | `#F6F7F6` | Primary cards, table containers, bottom status strip |
| `surfaceElevated` | `#2E302E` | `#FFFFFF` | Inputs, pill buttons, active segments, hover states |
| `surfaceSubtle` | `#202120` | `#EEF0EE` | Recessed sub-surfaces, expanded rows |
| `border` / `borderStrong` | `#353735` / `#4B4E4B` | `#D5D8D5` / `#B5BBB5` | Hairline borders and focused input outlines |
| `textPrimary` / `textSecondary` / `textMuted` | `#F0F2F0` / `#A0A5A0` / `#6E736E` | `#161816` / `#5D635D` / `#888E88` | Foreground text hierarchy |
| `znnGreen` / `qsrBlue` / `ztsMagenta` | `#4FD166` / `#3B8BFF` / `#FC54AE` | `#1DA84C` / `#0061EB` / `#E53D96` | Asset & brand accents adjusted for theme contrast |
| `warning` / `error` | `#E6B543` / `#F04465` | `#B37E0C` / `#D91F48` | Status indicators, validation errors, banners |
| `primaryGradient` | `#4FD166` → `#006AFF` | `#4FD166` → `#006AFF` | Signature Zenon green-to-blue CTA pill gradient |
| `monoStyle()` | `SF Mono` fallback stack + tabular numerals | Same | Addresses, hashes, and numeric columns |
| `microLabelStyle()` | `10.5px`, `w600`, `0.75` letter spacing | Same | Uppercase table column headers and metric labels |

## Code Generation (`build_runner`)

Syrius commits generated outputs to version control and verifies in `.github/workflows/pr-validation.yml` that regenerating them produces a clean `git diff`.

### Generators Configured in `pubspec.yaml` & `build.yaml`

| Generator | Input / Annotation | Generated Output |
| --- | --- | --- |
| `json_serializable` | `@JsonSerializable()` on BLoC states, models, and `SyriusException` subclasses | `*.g.dart` |
| `freezed` | `@freezed` models (e.g., `lib/rearchitecture/features/p2p_swap/model/p2p_swap.dart`) | `*.freezed.dart` |
| `hive_ce_generator` | `@GenerateAdapters(...)` in `lib/hive/hive_adapters.dart` | `lib/hive/hive_adapters.g.dart`, `lib/hive/hive_registrar.g.dart` |
| `drift_dev` | `@DriftDatabase(...)` in `htlc_swaps_database.dart` & `@DriftAccessor(...)` in `htlc_swaps_dao.dart` | `*.g.dart` (+ schema snapshot in `drift_schemas/`) |
| `bdd_widget_test` | `integration_test/features/*.feature` (configured in `build.yaml`) | `integration_test/features/*_test.dart`, step stubs, hooks |

Run code generation after changing any annotated model, Hive adapter, Drift schema, or Gherkin `.feature` file:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format integration_test
```

:::warning Keep generated files clean and committed
- CI's **PR Fast Validation** workflow runs `dart run build_runner build`, `dart format integration_test`, and `git diff --exit-code`. Any stale or uncommitted generated file will fail the PR check.
- Never manually lint-fix `*.g.dart` files; `analysis_options.yaml` explicitly excludes `**/*.g.dart`.
:::

## Static Analysis (`analysis_options.yaml`)

Syrius builds on [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) with repository-specific adjustments in `analysis_options.yaml`:

- **Excluded paths**: `**/*.g.dart`, `build/**`, and platform folders (`macos/**`, `windows/**`, `linux/**`, `android/**`, `ios/**`, `web/**`).
- **Mandatory explicit types**: `always_specify_types: true` is enabled for readability across a large codebase, while conflicting rules (`omit_local_variable_types: false`, `avoid_types_on_closure_parameters: false`, `no_default_cases: false`) are disabled.
- **Language checks**: `strict-casts`, `strict-inference`, and `strict-raw-types` are set to `false` to preserve compatibility with legacy code paths during the rearchitecture.

Run static analysis locally before committing:

```bash
flutter analyze
```
