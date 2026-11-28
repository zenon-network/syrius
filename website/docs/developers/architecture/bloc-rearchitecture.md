---
sidebar_position: 2
title: BLoC Rearchitecture Guide
description: Architectural principles and implementation conventions for Syrius's transition from legacy MVVM/BaseBloc to feature-based BLoC modules under lib/rearchitecture/features/.
---

# BLoC Rearchitecture Guide

Syrius has transitioned from a legacy layered MVVM architecture (`stacked` / `BaseBloc` extending `BaseViewModel`, which have now been removed from `lib/` and `pubspec.yaml`) to a **feature-based BLoC architecture** under `lib/rearchitecture/features/` (115 feature modules).

All new features and remaining UI/state refactors must follow the patterns documented on this page.

## Core Principles

1. **Feature-based organization over horizontal layers** — Group a feature's BLoC/Cubit, view widgets, repositories, models, and exceptions inside a single folder under `lib/rearchitecture/features/<feature_name>/`.
2. **BLoC as both state management and feature boundary** — Every feature owns explicit events/methods and immutable states (`Bloc` or `Cubit`), eliminating ad-hoc `ChangeNotifier` / `BaseViewModel` coupling.
3. **Stay close to `znn_sdk_dart` primitives** — Avoid unnecessary wrapper DTOs when `znn_sdk_dart` already provides typed domain models (`PillarInfo`, `UncollectedReward`, `DelegationInfo`, `Token`, `AccountBlock`).

## Preserving Git History When Refactoring

Most refactored features replace existing legacy widgets or view models. **Do not delete old files and create brand-new ones from scratch** when refactoring an existing feature:

- Move and rename the existing files into `lib/rearchitecture/features/<feature>/` (for example with `git mv`) and adapt them in place so `git log --follow` preserves file history and blame context.
- Migrate any remaining legacy `StatefulWidget` or `ChangeNotifier`-backed UI logic into proper `Bloc` or `Cubit` modules (extending `Bloc`, `Cubit`, `FetchBloc`, or `InfiniteListBloc`).

## Standard Feature Directory Layout

```text
lib/rearchitecture/features/<feature_name>/
├── <feature_name>.dart             # Barrel file exporting only the public API of this feature
├── bloc/                           # Or cubit/ for simpler state machines
│   ├── <feature_name>_bloc.dart
│   ├── <feature_name>_event.dart   # part of '<feature_name>_bloc.dart'
│   └── <feature_name>_state.dart   # part of '<feature_name>_bloc.dart'
├── view/
│   └── <feature_name>_card.dart    # Public {{Feature}}Card + private _View / _Populated widgets
├── data/                           # Optional: repositories, DAOs, local storage APIs
├── model/                          # Optional: feature-local models or freezed classes
└── exceptions/                     # Optional: feature-specific SyriusException subclasses
```

Export the feature's public entrypoints in `lib/rearchitecture/features/features.dart`.

## Reusable Base BLoCs (`lib/rearchitecture/utils/blocs/`)

Before writing a custom BLoC from scratch, check whether one of Syrius's hydrated base classes already fits your feature:

### `FetchBloc<T>` — Address-Scoped Single-Object Fetches

When a BLoC loads a single object for an `Address`, extend `FetchBloc<T extends Object>` (`lib/rearchitecture/utils/blocs/fetch_bloc/fetch_bloc.dart`).

`FetchBloc<T>` extends `HydratedBloc<FetchEvent, FetchState<T>>` and provides:

- Event: `FetchRequestData(address: Address)`
- Sealed states: `FetchInitial<T>`, `FetchPopulated<T>(data: T)`, `FetchFailure<T>(exception: SyriusException)`
- Built-in `ValueListenable<bool> get isLoadingListenable` for card refresh indicators
- Automatic JSON persistence via `fromJsonT` and `toJsonT`

Real example from `lib/rearchitecture/features/uncollected_pillar_rewards/bloc/uncollected_pillar_rewards_bloc.dart`:

```dart
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class UncollectedPillarRewardsBloc extends FetchBloc<UncollectedReward> {
  UncollectedPillarRewardsBloc({
    required super.zenon,
  }) : super(
         fromJsonT: UncollectedReward.fromJson,
         toJsonT: (UncollectedReward data) => data.toJson(),
       );

  @override
  Future<UncollectedReward> getData({required Address address}) =>
      zenon.embedded.pillar.getUncollectedReward(address);
}
```

### `InfiniteListBloc<T>` — Paginated Tables and Lists

When a feature fetches paginated SDK lists (such as Pillars, Sentinels, Stakes, Tokens, or Transactions), extend `InfiniteListBloc<T>` (`lib/rearchitecture/utils/blocs/infinite_list/infinite_list_bloc.dart`). It mixes in `RefreshBlocMixin` to automatically refresh after WebSocket reconnects and supports `InfiniteListRequested`, `InfiniteListMoreRequested`, and `InfiniteListRefreshRequested`.

Real example from `lib/rearchitecture/features/pillars/bloc/pillars_bloc.dart`:

```dart
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarsBloc extends InfiniteListBloc<PillarInfo> {
  PillarsBloc({required super.zenon, super.pageSize = kPageSize})
    : super(
        fromJsonT: (Object? map) => PillarInfo.fromJson(
          map! as Map<String, dynamic>,
        ),
        toJsonT: (PillarInfo pillarInfo) => pillarInfo.toJson(),
      );

  @override
  Future<List<PillarInfo>> paginationFetch({
    required int pageIndex,
    required int pageSize,
    Address? address,
  }) async {
    final PillarInfoList pillarInfoList = await zenon.embedded.pillar.getAll(
      pageIndex: pageIndex,
      pageSize: pageSize,
    );

    return pillarInfoList.list;
  }
}
```

### `RefreshBlocMixin` — Auto-Refreshing on WebSocket Reconnect

Custom BLoCs that query the Zenon node can mix in `RefreshBlocMixin` (`lib/rearchitecture/utils/blocs/refresh_bloc_mixin.dart`), call `listenToWsRestart(...)` in the constructor, and call `await cancelStreamSubscription()` inside `close()`.

## The `{{Feature}}Card` + `_View` + `_Populated` Widget Pattern

A feature widget that depends on a BLoC separates **dependency injection** from **state consumption** and **populated UI rendering**:

1. **Public `{{Feature}}Card` widget** — Initializes and injects feature-scoped BLoCs via `BlocProvider` / `MultiBlocProvider`, then renders `const _View()`.
2. **Private `_View` widget** — Consumes the BLoC via `BlocBuilder` / `BlocListener`, wraps content in `NewCardScaffold` (wired to `isLoadingListenable` and refresh callbacks), and switches over loading, error, and populated states.
3. **Private `_Populated` widget** — Renders the loaded state cleanly without cluttering `_View`.

See `PillarsCard` (`lib/rearchitecture/features/pillars/view/pillars_card.dart`) and `PillarRewardsCard` (`lib/rearchitecture/features/pillar_rewards_history/view/pillar_rewards_card.dart`) as canonical reference implementations:

```dart
class PillarsCard extends StatelessWidget {
  const PillarsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<DelegationBloc>(
          create: (_) => DelegationBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
          ),
        ),
      ],
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      isRefreshLoading: context.read<PillarsBloc>().isLoadingListenable,
      onRefreshPressed: () {
        context.read<PillarsBloc>().add(const InfiniteListRefreshRequested());
      },
      body: BlocBuilder<PillarsBloc, InfiniteListState<PillarInfo>>(
        builder: (_, InfiniteListState<PillarInfo> state) {
          return switch (state.status) {
            InfiniteListStatus.initial => const SyriusLoadingWidget(),
            InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
            InfiniteListStatus.success => _Populated(
              hasReachedMax: state.hasReachedMax,
              pillars: state.data!,
            ),
          };
        },
      ),
    );
  }
}
```

## Coding Conventions Checklist

Every feature under `lib/rearchitecture/features/` must obey these rules:

- **Private by default** — Keep classes, widgets, and helper functions private (`_View`, `_Populated`, `_CardHeader`) unless another feature genuinely needs to import them.
- **Private fields** — Make class fields private unless exposed intentionally as part of a public model/state/event API.
- **`_build*` prefix for widget helpers** — Inside a widget class, every helper method that returns a `Widget` (such as a `Row`, `Column`, or button) must start with `_build` (e.g., `_buildCollectButton()`, `_buildDelegateCell()`, `_buildHeaderColumns()` — not `_getCollectButton()`).
- **Explicit types everywhere** — `analysis_options.yaml` enables `always_specify_types: true`. Annotate local variables, generic type arguments (`<Widget>[]`, `<String, dynamic>{}`), and closure parameters.
- **Mandatory localization** — Replace hard-coded strings in refactored widgets with entries in `lib/l10n/app_en.arb` accessed via `context.l10n`. See [Localization and Theming](/docs/developers/architecture/localization-and-theming).
- **Required BLoC/Cubit unit tests** — Every new or refactored feature must include unit tests for its BLoC or Cubit under `test/<feature>/` (for example `test/pillars/bloc/pillars_bloc_test.dart` and `test/uncollected_pillar_rewards/bloc/uncollected_pillar_rewards_bloc_test.dart`). See [Unit and Widget Tests](/docs/developers/testing/unit-and-widget-tests).
