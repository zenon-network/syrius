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

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtilsHelper {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAccountBlockTemplate());
  });

  group('DelegateButtonCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late DelegateButtonCubit delegateButtonCubit;
    late AccountBlockTemplate testAccBlockTemplate;
    late MockAccountBlockUtils mockAccountBlockUtils;
    late CubitFailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtils = MockAccountBlockUtils();
      testAccBlockTemplate = AccountBlockTemplate(
        blockType: 1,
      );
      exception = CubitFailureException();

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

      delegateButtonCubit = DelegateButtonCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtils,
      );
    });

    tearDown(() {
      delegateButtonCubit.close();
    });

    test('initial state is correct', () {
      expect(
        delegateButtonCubit.state.status,
        equals(DelegateButtonStatus.initial),
      );
    });

    group('DelegateButtonCubit fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const DelegateButtonState initialState = DelegateButtonState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final DelegateButtonState deserialized =
            DelegateButtonState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const DelegateButtonState loadingState = DelegateButtonState(
          status: DelegateButtonStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final DelegateButtonState deserialized =
            DelegateButtonState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final AccountBlockTemplate testAccountBlockTemplate =
            AccountBlockTemplate(
          blockType: 1,
        );
        final DelegateButtonState successState = DelegateButtonState(
          status: DelegateButtonStatus.success,
          data: testAccountBlockTemplate,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final DelegateButtonState deserialized =
            DelegateButtonState.fromJson(serialized);

        expect(deserialized, isA<DelegateButtonState>());
        expect(deserialized.status, equals(DelegateButtonStatus.success));
        expect(deserialized.data, equals(testAccountBlockTemplate));
      });

      test('can (de)serialize failure state', () {
        final Exception testException = Exception('Test error');
        final DelegateButtonState failureState = DelegateButtonState(
          status: DelegateButtonStatus.failure,
          error: testException,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final DelegateButtonState deserialized =
            DelegateButtonState.fromJson(serialized);

        expect(deserialized, equals(failureState));
      });
    });

    group('delegateToPillar', () {
      blocTest<DelegateButtonCubit, DelegateButtonState>(
        'emits [loading, success] when delegateToPillar succeeds',
        build: () => delegateButtonCubit,
        act: (DelegateButtonCubit cubit) => cubit.delegateToPillar('test'),
        expect: () => <DelegateButtonState>[
          const DelegateButtonState(status: DelegateButtonStatus.loading),
          DelegateButtonState(
            status: DelegateButtonStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
      );

      blocTest<DelegateButtonCubit, DelegateButtonState>(
        'emits [loading, failure] when createAccountBlock throws an exception',
        setUp: () {
          when(() => mockPillarApi.delegate(any())).thenThrow(exception);
        },
        build: () => delegateButtonCubit,
        act: (DelegateButtonCubit cubit) => cubit.delegateToPillar('test'),
        expect: () => <DelegateButtonState>[
          const DelegateButtonState(status: DelegateButtonStatus.loading),
          DelegateButtonState(
            status: DelegateButtonStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
