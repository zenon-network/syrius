import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars_deposit_qsr/cubit/pillars_deposit_qsr_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/zenon_address_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtilsHelper {}

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtilsHelper {}


void main() {
  initHydratedStorage();

  setUpAll(() {
    final BigInt testAmount = BigInt.from(1000);

    registerFallbackValue(FakeAccountBlockTemplate());
    registerFallbackValue(testAmount);
  });

  group('PillarsDepositQsrCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late MockAccountBlockUtils mockAccountBlockUtilsHelper;
    late MockZenonAddressUtils mockZenonAddressUtils;
    late CubitFailureException exception;
    late PillarsDepositQsrCubit pillarsDepositQsrCubit;
    late AccountBlockTemplate testAccBlockTemplate;
    late BigInt testAmount;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtilsHelper = MockAccountBlockUtils();
      mockZenonAddressUtils = MockZenonAddressUtils();
      testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
      testAmount = BigInt.from(1000);
      exception = CubitFailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockZenonAddressUtils.refreshBalance())
          .thenAnswer((_) async {});

      pillarsDepositQsrCubit = PillarsDepositQsrCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
        zenonAddressUtilsHelper: mockZenonAddressUtils,
      );
    });

    tearDown(() {
      pillarsDepositQsrCubit.close();
    });

    test('initial state is correct', () {
      expect(
        pillarsDepositQsrCubit.state.status,
        PillarsDepositQsrStatus.initial,
      );
    });

    group('depositQsr', () {
      blocTest<PillarsDepositQsrCubit, PillarsDepositQsrState>(
        'emits [loading, success] with data when depositQsr succeeds',
        setUp: () {
          when(() => mockPillarApi.depositQsr(any()))
              .thenReturn(testAccBlockTemplate);
          when(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              any(),
              waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
            ),
          ).thenAnswer((_) async => testAccBlockTemplate);
        },
        build: () => pillarsDepositQsrCubit,
        act: (PillarsDepositQsrCubit cubit) => cubit.depositQsr(testAmount),
        expect: () => <PillarsDepositQsrState>[
          const PillarsDepositQsrState(status: PillarsDepositQsrStatus.loading),
          PillarsDepositQsrState(
            status: PillarsDepositQsrStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
      );

      blocTest<PillarsDepositQsrCubit, PillarsDepositQsrState>(
        'emits [loading, success] when justMarkStepCompleted is true',
        build: () => pillarsDepositQsrCubit,
        act: (PillarsDepositQsrCubit cubit) =>
            cubit.depositQsr(testAmount, justMarkStepCompleted: true),
        expect: () => <PillarsDepositQsrState>[
          const PillarsDepositQsrState(status: PillarsDepositQsrStatus.loading),
          const PillarsDepositQsrState(status: PillarsDepositQsrStatus.success),
        ],
        verify: (_) {
          verifyNever(() => mockPillarApi.depositQsr(any()));
          verifyNever(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              any(),
              waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
            ),
          );
        },
      );

      blocTest<PillarsDepositQsrCubit, PillarsDepositQsrState>(
        'emits [loading, failure] when createAccountBlock throws an exception',
        setUp: () {
          when(() => mockPillarApi.depositQsr(any())).thenThrow(exception);
        },
        build: () => pillarsDepositQsrCubit,
        act: (PillarsDepositQsrCubit cubit) => cubit.depositQsr(testAmount),
        expect: () => <PillarsDepositQsrState>[
          const PillarsDepositQsrState(status: PillarsDepositQsrStatus.loading),
          PillarsDepositQsrState(
            status: PillarsDepositQsrStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
