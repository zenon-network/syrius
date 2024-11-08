import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars_deploy/cubit/pillars_deploy_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars_deploy/exceptions/pillar_name_already_exists_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/zenon_address_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillar_widgets/pillar_stepper_container.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class FakeAddress extends Fake implements Address {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtilsHelper {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtilsHelper {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAccountBlockTemplate());
    registerFallbackValue(FakeAddress());
  });

  group('PillarsDeployCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late MockAccountBlockUtils mockAccountBlockUtilsHelper;
    late MockZenonAddressUtils mockZenonAddressUtils;
    late PillarsDeployCubit pillarsDeployCubit;
    late AccountBlockTemplate testAccBlockTemplate;
    late PillarNameAlreadyExistsException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtilsHelper = MockAccountBlockUtils();
      mockZenonAddressUtils = MockZenonAddressUtils();
      exception = PillarNameAlreadyExistsException();
      testAccBlockTemplate = AccountBlockTemplate(
        blockType: 1,
      );

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockZenonAddressUtils.refreshBalance())
          .thenAnswer((_) async {});

      pillarsDeployCubit = PillarsDeployCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
        zenonAddressUtilsHelper: mockZenonAddressUtils,
      );
    });

    tearDown(() {
      pillarsDeployCubit.close();
    });

    test('initial state is correct', () {
      expect(pillarsDeployCubit.state.status, PillarsDeployStatus.initial);
    });

    group('deployPillar', () {
      blocTest<PillarsDeployCubit, PillarsDeployState>(
        'emits [loading, success] when deployPillar succeeds',
        setUp: () {
          when(() => mockPillarApi.checkNameAvailability(any()))
              .thenAnswer((_) async => true);

          when(() => mockPillarApi.register(any(), any(), any(), any(), any()))
              .thenReturn(testAccBlockTemplate);

          when(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              any(),
              waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
            ),
          ).thenAnswer((_) async => testAccBlockTemplate);
          },
        build: () => pillarsDeployCubit,
        act: (PillarsDeployCubit cubit) => cubit.deployPillar(
          pillarType: PillarType.regularPillar,
          // Adjust pillar type if necessary
          pillarName: 'testPillar',
          rewardAddress: emptyAddress.toString(),
          blockProducingAddress: emptyAddress.toString(),
          giveBlockRewardPercentage: 50,
          giveDelegateRewardPercentage: 50,
        ),
        expect: () => <PillarsDeployState>[
          const PillarsDeployState(status: PillarsDeployStatus.loading),
          PillarsDeployState(
            status: PillarsDeployStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
      );

      blocTest<PillarsDeployCubit, PillarsDeployState>(
        'emits [loading, failure] when pillar name already exists',
        setUp: () {
          when(() => mockPillarApi.checkNameAvailability(any()))
              .thenAnswer((_) async => false);
        },
        build: () => pillarsDeployCubit,
        act: (PillarsDeployCubit cubit) => cubit.deployPillar(
          pillarType: PillarType.regularPillar,
          pillarName: 'testPillar',
          rewardAddress: emptyAddress.toString(),
          blockProducingAddress: emptyAddress.toString(),
          giveBlockRewardPercentage: 50,
          giveDelegateRewardPercentage: 50,
        ),
        expect: () => <PillarsDeployState>[
          const PillarsDeployState(status: PillarsDeployStatus.loading),
          PillarsDeployState(
            status: PillarsDeployStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
