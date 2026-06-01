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
class FakeAddress extends Fake implements Address {}
class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();
  setUpAll(() {
    registerFallbackValue(FakeAddress());
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('DelegationBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPillarApi pillarApi;
    late MockAccountBlockUtils accountBlockUtils;
    late DelegationBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      pillarApi = MockPillarApi();
      accountBlockUtils = MockAccountBlockUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.pillar).thenReturn(pillarApi);
      when(() => pillarApi.delegate(any())).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);

      bloc = DelegationBloc(accountBlockUtils: accountBlockUtils, zenon: zenon);
    });

    test('initial state is correct', () {
      expect(bloc.state, const DelegationInitial());
    });

    blocTest<DelegationBloc, DelegationState>(
      'emits loading and calls dependencies on successful delegation',
      build: () => bloc,
      act: (DelegationBloc bloc) => bloc.add(
        DelegationRequested(address: emptyAddress, pillarName: 'pillar'),
      ),
      verify: (_) {
        verify(() => pillarApi.delegate('pillar')).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            template,
            'delegate to Pillar',
            address: emptyAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
      },
      expect: () => <DelegationState>[
        const DelegationLoading(),
      ],
    );

    blocTest<DelegationBloc, DelegationState>(
      'emits [loading, failure] when SyriusException is thrown',
      setUp: () {
        when(() => pillarApi.delegate(any())).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (DelegationBloc bloc) => bloc.add(
        DelegationRequested(address: emptyAddress, pillarName: 'pillar'),
      ),
      expect: () => <Matcher>[
        isA<DelegationLoading>(),
        isA<DelegationFailure>().having(
          (DelegationFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
