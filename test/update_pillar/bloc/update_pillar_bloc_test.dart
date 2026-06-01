import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();
  setUpAll(() {
    registerFallbackValue(FakeAddress());
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('UpdatePillarBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPillarApi pillarApi;
    late MockAccountBlockUtils accountBlockUtils;
    late UpdatePillarBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      pillarApi = MockPillarApi();
      accountBlockUtils = MockAccountBlockUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.pillar).thenReturn(pillarApi);
      when(
        () => pillarApi.updatePillar(any(), any(), any(), any(), any()),
      ).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(any(), any()),
      ).thenAnswer((_) async => template);

      bloc = UpdatePillarBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const UpdatePillarInitial());
    });

    blocTest<UpdatePillarBloc, UpdatePillarState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (UpdatePillarBloc bloc) => bloc.add(
        UpdatePillarRequested(
          blockProducingAddress: emptyAddress,
          giveBlockRewardPercentage: 1,
          giveDelegateRewardPercentage: 1,
          pillarName: 'pillar',
          rewardAddress: emptyAddress,
        ),
      ),
      expect: () => <UpdatePillarState>[
        const UpdatePillarLoading(),
        const UpdatePillarDone(),
      ],
    );

    blocTest<UpdatePillarBloc, UpdatePillarState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => pillarApi.updatePillar(any(), any(), any(), any(), any()),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (UpdatePillarBloc bloc) => bloc.add(
        UpdatePillarRequested(
          blockProducingAddress: emptyAddress,
          giveBlockRewardPercentage: 1,
          giveDelegateRewardPercentage: 1,
          pillarName: 'pillar',
          rewardAddress: emptyAddress,
        ),
      ),
      expect: () => <Matcher>[
        isA<UpdatePillarLoading>(),
        isA<UpdatePillarFailure>().having(
          (UpdatePillarFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
