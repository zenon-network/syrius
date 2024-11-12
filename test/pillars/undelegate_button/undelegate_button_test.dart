import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class MockAccountBlockUtilsHelper extends Mock
    implements AccountBlockUtilsHelper {}

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  registerFallbackValue(FakeAccountBlockTemplate());

  group('UndelegateButtonCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late MockAccountBlockUtilsHelper mockAccountBlockUtilsHelper;
    late UndelegateButtonCubit undelegateButtonCubit;
    late AccountBlockTemplate testAccountBlockTemplate;
    late CubitFailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtilsHelper = MockAccountBlockUtilsHelper();
      testAccountBlockTemplate = AccountBlockTemplate(blockType: 1);
      exception = CubitFailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockPillarApi.undelegate())
          .thenReturn(testAccountBlockTemplate);
      when(
        () => mockAccountBlockUtilsHelper.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => testAccountBlockTemplate);

      undelegateButtonCubit = UndelegateButtonCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
      );
    });

    tearDown(() {
      undelegateButtonCubit.close();
    });

    test('initial state is correct', () {
      expect(
        undelegateButtonCubit.state.status,
        UndelegateButtonStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const UndelegateButtonState initialState = UndelegateButtonState();

        final Map<String, dynamic>? serialized =
            undelegateButtonCubit.toJson(initialState);

        final UndelegateButtonState? deserialized =
            undelegateButtonCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const UndelegateButtonState loadingState = UndelegateButtonState(
          status: UndelegateButtonStatus.loading,
        );

        final Map<String, dynamic>? serialized =
            undelegateButtonCubit.toJson(loadingState);

        final UndelegateButtonState? deserialized =
            undelegateButtonCubit.fromJson(serialized!);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final UndelegateButtonState successState = UndelegateButtonState(
          status: UndelegateButtonStatus.success,
          data: testAccountBlockTemplate,
        );

        final Map<String, dynamic>? serialized =
            undelegateButtonCubit.toJson(successState);

        final UndelegateButtonState? deserialized =
            undelegateButtonCubit.fromJson(serialized!);

        expect(deserialized, isA<UndelegateButtonState>());
        expect(deserialized!.status, equals(UndelegateButtonStatus.success));
        expect(deserialized.data, equals(successState.data));
      });

      test('can (de)serialize failure state', () {
        final UndelegateButtonState failureState = UndelegateButtonState(
          status: UndelegateButtonStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized =
            undelegateButtonCubit.toJson(failureState);

        final UndelegateButtonState? deserialized =
            undelegateButtonCubit.fromJson(serialized!);

        expect(deserialized, equals(failureState));
      });
    });

    blocTest<UndelegateButtonCubit, UndelegateButtonState>(
      'emits [loading, success] when cancelPillarVoting succeeds',
      build: () => undelegateButtonCubit,
      act: (UndelegateButtonCubit cubit) => cubit.cancelPillarVoting(),
      expect: () => <UndelegateButtonState>[
        const UndelegateButtonState(status: UndelegateButtonStatus.loading),
        UndelegateButtonState(
          status: UndelegateButtonStatus.success,
          data: testAccountBlockTemplate,
        ),
      ],
    );

    blocTest<UndelegateButtonCubit, UndelegateButtonState>(
      'emits [loading, failure] when cancelPillarVoting throws an exception',
      setUp: () {
        when(
          () => mockAccountBlockUtilsHelper.createAccountBlock(
            any(),
            any(),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenThrow(exception);
      },
      build: () => undelegateButtonCubit,
      act: (UndelegateButtonCubit cubit) => cubit.cancelPillarVoting(),
      expect: () => <UndelegateButtonState>[
        const UndelegateButtonState(status: UndelegateButtonStatus.loading),
        UndelegateButtonState(
          status: UndelegateButtonStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
