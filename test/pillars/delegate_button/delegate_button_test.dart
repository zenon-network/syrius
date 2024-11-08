import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/delegate_button/cubit/delegate_button_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
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
