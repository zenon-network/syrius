import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pillar_stepper/view/create_pillar_stepper_view.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class FakeAddress extends Fake implements Address {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

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
    late MockAccountBlockUtils mockAccountBlockUtils;
    late MockZenonAddressUtils mockZenonAddressUtils;
    late PillarsDeployCubit pillarsDeployCubit;
    late AccountBlockTemplate testAccBlockTemplate;
    late PillarNameAlreadyExistsException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtils = MockAccountBlockUtils();
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
        accountBlockUtilsHelper: mockAccountBlockUtils,
        zenonAddressUtilsHelper: mockZenonAddressUtils,
      );
    });

    tearDown(() {
      pillarsDeployCubit.close();
    });

    test('initial state is correct', () {
      expect(pillarsDeployCubit.state.status, PillarsDeployStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const PillarsDeployState initialState = PillarsDeployState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final PillarsDeployState deserialized =
            PillarsDeployState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const PillarsDeployState loadingState = PillarsDeployState(
          status: PillarsDeployStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final PillarsDeployState deserialized =
            PillarsDeployState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final PillarsDeployState successState = PillarsDeployState(
          status: PillarsDeployStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final PillarsDeployState deserialized =
            PillarsDeployState.fromJson(serialized);

        expect(deserialized, isA<PillarsDeployState>());
        expect(deserialized.status, equals(PillarsDeployStatus.success));
        expect(deserialized.data, equals(testAccBlockTemplate));
      });

      test('can (de)serialize failure state', () {
        final PillarsDeployState failureState = PillarsDeployState(
          status: PillarsDeployStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final PillarsDeployState deserialized =
            PillarsDeployState.fromJson(serialized);

        expect(deserialized, equals(failureState));
      });
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
            () => mockAccountBlockUtils.createAccountBlock(
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
