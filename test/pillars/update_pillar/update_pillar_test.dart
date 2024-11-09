import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/update_pillar/cubit/update_pillar_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class MockAccountBlockUtilsHelper extends Mock
    implements AccountBlockUtilsHelper {}

class FakeAddress extends Fake implements Address {}

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  registerFallbackValue(FakeAddress());
  registerFallbackValue(FakeAccountBlockTemplate());

  group('UpdatePillarCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late MockAccountBlockUtilsHelper mockAccountBlockUtilsHelper;
    late UpdatePillarCubit updatePillarCubit;
    late AccountBlockTemplate testAccountBlockTemplate;
    late Address testAddress;
    late Exception exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtilsHelper = MockAccountBlockUtilsHelper();
      testAccountBlockTemplate = AccountBlockTemplate(blockType: 1);
      testAddress = emptyAddress;
      exception = CubitFailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(
        () => mockPillarApi.updatePillar(
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenReturn(testAccountBlockTemplate);

      when(
        () => mockAccountBlockUtilsHelper.createAccountBlock(
          any(),
          any(),
        ),
      ).thenAnswer((_) async => testAccountBlockTemplate);

      updatePillarCubit = UpdatePillarCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
      );
    });

    tearDown(() {
      updatePillarCubit.close();
    });

    test('initial state is correct', () {
      expect(updatePillarCubit.state.status, UpdatePillarStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const UpdatePillarState initialState = UpdatePillarState();

        final Map<String, dynamic>? serialized =
            updatePillarCubit.toJson(initialState);
        final UpdatePillarState? deserialized =
            updatePillarCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const UpdatePillarState loadingState = UpdatePillarState(
          status: UpdatePillarStatus.loading,
        );

        final Map<String, dynamic>? serialized =
            updatePillarCubit.toJson(loadingState);
        final UpdatePillarState? deserialized =
            updatePillarCubit.fromJson(serialized!);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final UpdatePillarState successState = UpdatePillarState(
          status: UpdatePillarStatus.success,
          data: testAccountBlockTemplate,
        );

        final Map<String, dynamic>? serialized =
            updatePillarCubit.toJson(successState);
        final UpdatePillarState? deserialized =
            updatePillarCubit.fromJson(serialized!);

        expect(deserialized, isA<UpdatePillarState>());
        expect(deserialized!.status, equals(UpdatePillarStatus.success));
        expect(deserialized.data, equals(successState.data));
      });

      test('can (de)serialize failure state', () {
        final UpdatePillarState failureState = UpdatePillarState(
          status: UpdatePillarStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized =
            updatePillarCubit.toJson(failureState);
        final UpdatePillarState? deserialized =
            updatePillarCubit.fromJson(serialized!);

        expect(deserialized, equals(failureState));
      });
    });

    blocTest<UpdatePillarCubit, UpdatePillarState>(
      'emits [loading, success] when updatePillar succeeds',
      build: () => updatePillarCubit,
      act: (UpdatePillarCubit cubit) => cubit.updatePillar(
        'pillarName',
        testAddress,
        testAddress,
        10,
        20,
      ),
      expect: () => <UpdatePillarState>[
        const UpdatePillarState(status: UpdatePillarStatus.loading),
        UpdatePillarState(
          status: UpdatePillarStatus.success,
          data: testAccountBlockTemplate,
        ),
      ],
    );

    blocTest<UpdatePillarCubit, UpdatePillarState>(
      'emits [loading, failure] when updatePillar throws an exception',
      setUp: () {
        when(
          () => mockAccountBlockUtilsHelper.createAccountBlock(
            any(),
            any(),
          ),
        ).thenThrow(exception);
      },
      build: () => updatePillarCubit,
      act: (UpdatePillarCubit cubit) => cubit.updatePillar(
        'pillarName',
        testAddress,
        testAddress,
        10,
        20,
      ),
      expect: () => <UpdatePillarState>[
        const UpdatePillarState(status: UpdatePillarStatus.loading),
        UpdatePillarState(
          status: UpdatePillarStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
