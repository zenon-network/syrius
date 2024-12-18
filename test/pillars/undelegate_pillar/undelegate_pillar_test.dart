import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  registerFallbackValue(FakeAccountBlockTemplate());

  group('UndelegatePillarCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late MockAccountBlockUtils mockAccountBlockUtils;
    late UndelegatePillarCubit undelegatePillarCubit;
    late AccountBlockTemplate testAccountBlockTemplate;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtils = MockAccountBlockUtils();
      testAccountBlockTemplate = AccountBlockTemplate(blockType: 1);
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockPillarApi.undelegate())
          .thenReturn(testAccountBlockTemplate);
      when(
        () => mockAccountBlockUtils.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => testAccountBlockTemplate);

      undelegatePillarCubit = UndelegatePillarCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtils,
      );
    });

    tearDown(() {
      undelegatePillarCubit.close();
    });

    test('initial state is correct', () {
      expect(
        undelegatePillarCubit.state.status,
        UndelegatePillarStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const UndelegatePillarState initialState = UndelegatePillarState();

        final Map<String, dynamic>? serialized =
            undelegatePillarCubit.toJson(initialState);

        final UndelegatePillarState? deserialized =
            undelegatePillarCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const UndelegatePillarState loadingState = UndelegatePillarState(
          status: UndelegatePillarStatus.loading,
        );

        final Map<String, dynamic>? serialized =
            undelegatePillarCubit.toJson(loadingState);

        final UndelegatePillarState? deserialized =
            undelegatePillarCubit.fromJson(serialized!);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final UndelegatePillarState successState = UndelegatePillarState(
          status: UndelegatePillarStatus.success,
          data: testAccountBlockTemplate,
        );

        final Map<String, dynamic>? serialized =
            undelegatePillarCubit.toJson(successState);

        final UndelegatePillarState? deserialized =
            undelegatePillarCubit.fromJson(serialized!);

        expect(deserialized, isA<UndelegatePillarState>());
        expect(deserialized!.status, equals(UndelegatePillarStatus.success));
        expect(deserialized.data, equals(successState.data));
      });

      test('can (de)serialize failure state', () {
        final UndelegatePillarState failureState = UndelegatePillarState(
          status: UndelegatePillarStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized =
            undelegatePillarCubit.toJson(failureState);

        final UndelegatePillarState? deserialized =
            undelegatePillarCubit.fromJson(serialized!);

        expect(deserialized, equals(failureState));
      });
    });

    blocTest<UndelegatePillarCubit, UndelegatePillarState>(
      'emits [loading, success] when cancelPillarVoting succeeds',
      build: () => undelegatePillarCubit,
      act: (UndelegatePillarCubit cubit) => cubit.cancelPillarVoting(),
      expect: () => <UndelegatePillarState>[
        const UndelegatePillarState(status: UndelegatePillarStatus.loading),
        UndelegatePillarState(
          status: UndelegatePillarStatus.success,
          data: testAccountBlockTemplate,
        ),
      ],
    );

    blocTest<UndelegatePillarCubit, UndelegatePillarState>(
      'emits [loading, failure] when cancelPillarVoting throws an exception',
      setUp: () {
        when(
          () => mockAccountBlockUtils.createAccountBlock(
            any(),
            any(),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenThrow(exception);
      },
      build: () => undelegatePillarCubit,
      act: (UndelegatePillarCubit cubit) => cubit.cancelPillarVoting(),
      expect: () => <UndelegatePillarState>[
        const UndelegatePillarState(status: UndelegatePillarStatus.loading),
        UndelegatePillarState(
          status: UndelegatePillarStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
