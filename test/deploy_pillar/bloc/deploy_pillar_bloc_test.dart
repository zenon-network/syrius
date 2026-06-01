import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();
  setUpAll(() {
    registerFallbackValue(FakeAddress());
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('DeployPillarBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPillarApi pillarApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late DeployPillarBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      pillarApi = MockPillarApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.pillar).thenReturn(pillarApi);
      when(
        () => pillarApi.checkNameAvailability(any()),
      ).thenAnswer((_) async => true);
      when(
        () => pillarApi.register(any(), any(), any(), any(), any()),
      ).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = DeployPillarBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const DeployPillarInitial());
    });

    blocTest<DeployPillarBloc, DeployPillarState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (DeployPillarBloc bloc) => bloc.add(
        DeployPillarRequested(
          blockProducingAddress: emptyAddress,
          giveBlockRewardPercentage: 1,
          giveDelegateRewardPercentage: 1,
          pillarName: 'pillar',
          rewardAddress: emptyAddress,
        ),
      ),
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <DeployPillarState>[
        const DeployPillarLoading(),
        const DeployPillarDone(),
      ],
    );

    blocTest<DeployPillarBloc, DeployPillarState>(
      'emits failure when pillar name already exists',
      setUp: () {
        when(
          () => pillarApi.checkNameAvailability(any()),
        ).thenAnswer((_) async => false);
      },
      build: () => bloc,
      act: (DeployPillarBloc bloc) => bloc.add(
        DeployPillarRequested(
          blockProducingAddress: emptyAddress,
          giveBlockRewardPercentage: 1,
          giveDelegateRewardPercentage: 1,
          pillarName: 'pillar',
          rewardAddress: emptyAddress,
        ),
      ),
      expect: () => <Matcher>[
        isA<DeployPillarLoading>(),
        isA<DeployPillarFailure>().having(
          (DeployPillarFailure s) => s.exception,
          'exception',
          isA<PillarNameAlreadyExistsException>(),
        ),
      ],
    );
  });
}
