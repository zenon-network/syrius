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

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAccountBlockTemplate());
  });

  group('DelegatePillarCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late DelegatePillarCubit delegatePillarCubit;
    late AccountBlockTemplate testAccBlockTemplate;
    late MockAccountBlockUtils mockAccountBlockUtils;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtils = MockAccountBlockUtils();
      testAccBlockTemplate = AccountBlockTemplate(
        blockType: 1,
      );
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockPillarApi.delegate(any()))
          .thenReturn(testAccBlockTemplate);
      when(
        () => mockAccountBlockUtils.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => testAccBlockTemplate);

      delegatePillarCubit = DelegatePillarCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtils,
      );
    });

    tearDown(() {
      delegatePillarCubit.close();
    });

    test('initial state is correct', () {
      expect(
        delegatePillarCubit.state.status,
        equals(DelegatePillarStatus.initial),
      );
    });

    group('DelegatePillarCubit fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const DelegatePillarState initialState = DelegatePillarState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final DelegatePillarState deserialized =
            DelegatePillarState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const DelegatePillarState loadingState = DelegatePillarState(
          status: DelegatePillarStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final DelegatePillarState deserialized =
            DelegatePillarState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final AccountBlockTemplate testAccountBlockTemplate =
            AccountBlockTemplate(
          blockType: 1,
        );
        final DelegatePillarState successState = DelegatePillarState(
          status: DelegatePillarStatus.success,
          data: testAccountBlockTemplate,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final DelegatePillarState deserialized =
            DelegatePillarState.fromJson(serialized);

        expect(deserialized, isA<DelegatePillarState>());
        expect(deserialized.status, equals(DelegatePillarStatus.success));
        expect(deserialized.data, equals(testAccountBlockTemplate));
      });

      test('can (de)serialize failure state', () {
        final Exception testException = Exception('Test error');
        final DelegatePillarState failureState = DelegatePillarState(
          status: DelegatePillarStatus.failure,
          error: testException,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final DelegatePillarState deserialized =
            DelegatePillarState.fromJson(serialized);

        expect(deserialized, equals(failureState));
      });
    });

    group('delegateToPillar', () {
      blocTest<DelegatePillarCubit, DelegatePillarState>(
        'emits [loading, success] when delegateToPillar succeeds',
        build: () => delegatePillarCubit,
        act: (DelegatePillarCubit cubit) => cubit.delegateToPillar('test'),
        expect: () => <DelegatePillarState>[
          const DelegatePillarState(status: DelegatePillarStatus.loading),
          DelegatePillarState(
            status: DelegatePillarStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
      );

      blocTest<DelegatePillarCubit, DelegatePillarState>(
        'emits [loading, failure] when createAccountBlock throws an exception',
        setUp: () {
          when(() => mockPillarApi.delegate(any())).thenThrow(exception);
        },
        build: () => delegatePillarCubit,
        act: (DelegatePillarCubit cubit) => cubit.delegateToPillar('test'),
        expect: () => <DelegatePillarState>[
          const DelegatePillarState(status: DelegatePillarStatus.loading),
          DelegatePillarState(
            status: DelegatePillarStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
