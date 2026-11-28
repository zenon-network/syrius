---
sidebar_position: 1
title: Unit and Widget Tests
description: How to run Flutter unit, BLoC, Cubit, and widget tests locally, mock Zenon SDK and HydratedBloc storage, and validate code generation and CI scripts.
---

# Unit and Widget Tests

Syrius maintains a fast, fully mocked unit and widget test suite under `test/` (172 `*_test.dart` files) covering BLoCs, Cubits, repositories, encrypted Drift DAOs, WalletConnect services, Hive adapters, and UI widgets.

Fast unit and widget tests under `test/` are intentionally kept separate from live-devnet [Blockchain Integration Tests](/docs/developers/testing/blockchain-integration-tests) under `integration_test/`.

## Running Tests Locally

```bash
# Run all fast unit and widget tests (mirrors CI)
flutter test test --exclude-tags chain

# Run the default test command across the repo
flutter test

# Run a single test file
flutter test test/pillars/bloc/pillars_bloc_test.dart

# Run static analysis
flutter analyze
```

:::info Filtering the `chain` tag
`dart_test.yaml` registers the `chain` tag for devnet-dependent integration tests. Always use `--exclude-tags chain` when running fast mocked checks locally or in CI.
:::

### Checking Generated Outputs and CI Scripts

Before opening a pull request, you can run the same extra checks executed by `.github/workflows/pr-validation.yml`:

```bash
# Verify committed generated Dart files are up to date
dart run build_runner build
dart format integration_test
git diff --exit-code

# Verify Python CI helper scripts and embedded libznn provenance manifest
python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v
python3 .github/scripts/verify_libznn_manifest.py --repo-root .
```

## Testing Stack

Declared under `dev_dependencies` in `pubspec.yaml`:

- **`flutter_test`** — Core Dart test runner and Flutter widget test harness (`testWidgets`).
- **`bloc_test`** (`^10.0.0`) — Declarative `blocTest<B, S>` assertions for BLoC/Cubit event-to-state transitions.
- **`mocktail`** (`^1.0.4`) — Null-safe mocking (`Mock`, `Fake`, `when`, `verify`, `registerFallbackValue`) without extra code generation.

## Mocking `HydratedBloc` Storage

Because `FetchBloc` and `InfiniteListBloc` extend `HydratedBloc`, tests must initialize an in-memory mocked `Storage` before instantiating those BLoCs. Syrius provides a shared helper in `test/helpers/hydrated_bloc.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements Storage {}

late Storage hydratedStorage;

void initHydratedStorage() {
  TestWidgetsFlutterBinding.ensureInitialized();
  hydratedStorage = MockStorage();
  when(
    () => hydratedStorage.write(any(), any<dynamic>()),
  ).thenAnswer((_) async {});
  HydratedBloc.storage = hydratedStorage;
}
```

Call `initHydratedStorage()` at the top of `main()` in any `HydratedBloc` test file so `HydratedBloc.storage` never writes to disk.

## BLoC & Cubit Testing Patterns

Every new or refactored feature under `lib/rearchitecture/features/` must include unit tests under `test/<feature>/`.

### Testing a `FetchBloc` Subclass

Example adapted from `test/uncollected_pillar_rewards/bloc/uncollected_pillar_rewards_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}
class MockEmbedded extends Mock implements EmbeddedApi {}
class MockPillar extends Mock implements PillarApi {}
class MockUncollectedReward extends Mock implements UncollectedReward {}
class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('UncollectedPillarRewardsBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late UncollectedPillarRewardsBloc bloc;
    late MockUncollectedReward reward;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      reward = MockUncollectedReward();
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
      when(() => reward.toJson()).thenReturn(<String, dynamic>{
        'znnAmount': '1',
        'qsrAmount': '1',
      });
      when(
        () => mockPillar.getUncollectedReward(any()),
      ).thenAnswer((_) async => reward);

      bloc = UncollectedPillarRewardsBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<UncollectedReward>());
    });

    blocTest<UncollectedPillarRewardsBloc, FetchState<UncollectedReward>>(
      'calls getUncollectedReward once and emits populated state',
      build: () => bloc,
      act: (UncollectedPillarRewardsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockPillar.getUncollectedReward(emptyAddress)).called(1);
      },
      expect: () => <FetchState<UncollectedReward>>[
        FetchPopulated<UncollectedReward>(data: reward),
      ],
    );

    blocTest<UncollectedPillarRewardsBloc, FetchState<UncollectedReward>>(
      'emits failure when getUncollectedReward throws',
      setUp: () {
        when(() => mockPillar.getUncollectedReward(any())).thenThrow(exception);
      },
      build: () => bloc,
      act: (UncollectedPillarRewardsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<UncollectedReward>>[
        FetchFailure<UncollectedReward>(exception: exception),
      ],
    );
  });
}
```

:::tip Mock `toJson()` on hydrated domain objects
When testing a `FetchBloc` or `InfiniteListBloc` with a `Mock` SDK entity (such as `MockUncollectedReward` or `MockPillarInfo`), stub `entity.toJson()` in `setUp()`. `HydratedBloc` serializes emitted states through `toJson()` right after `emit()`.
:::

### Testing an `InfiniteListBloc` Subclass

See `test/pillars/bloc/pillars_bloc_test.dart` and `test/sentinels/bloc/sentinels_bloc_test.dart` for canonical pagination tests verifying:

- Initial `InfiniteListState<T>.initial()`
- `InfiniteListRequested` emitting `InfiniteListStatus.success` with expected `hasReachedMax`
- `InfiniteListStatus.failure` when the SDK API throws

## Reference Tests Across the Codebase

When adding tests for other subsystems, mirror these existing files under `test/`:

| Subsystem | Reference Test Path |
| --- | --- |
| `FetchBloc` | `test/uncollected_pillar_rewards/bloc/uncollected_pillar_rewards_bloc_test.dart` |
| `InfiniteListBloc` | `test/pillars/bloc/pillars_bloc_test.dart`, `test/sentinels/bloc/sentinels_bloc_test.dart` |
| Feature Widget Tests | `test/notifications/view/notifications_card_test.dart`, `test/onboarding/view/onboarding_screens_test.dart`, `test/tokens/view/tokens_card_test.dart` |
| Drift DAO & HTLC Services | `test/p2p_swaps/data/htlc_swaps_dao_test.dart`, `test/p2p_swaps/services/htlc_swap_sync_service_test.dart` |
| Hive Adapters | `test/hive/hive_adapters_test.dart` |
| WalletConnect / Reown Services | `test/services/web3wallet_service_test.dart`, `test/services/nom_service_test.dart` |
| Shared Rearchitecture Utilities | `test/rearchitecture/utils/blocs/refresh_bloc_mixin_test.dart`, `test/rearchitecture/utils/l10n/app_localizations_resolver_test.dart` |
