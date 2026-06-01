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
class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}
class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}
class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();
  setUpAll(() {
    registerFallbackValue(FakeAddress());
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(BigInt.one);
  });

  group('PillarDepositQsrBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPillarApi pillarApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late PillarDepositQsrBloc bloc;
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
      when(() => pillarApi.depositQsr(any())).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = PillarDepositQsrBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const PillarDepositQsrInitial());
    });

    blocTest<PillarDepositQsrBloc, PillarDepositQsrState>(
      'emits loading and calls dependencies on success',
      build: () => bloc,
      act: (PillarDepositQsrBloc bloc) => bloc.add(
        PillarDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      expect: () => <PillarDepositQsrState>[
        const PillarDepositQsrLoading(),
      ],
    );

    blocTest<PillarDepositQsrBloc, PillarDepositQsrState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => pillarApi.depositQsr(any())).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (PillarDepositQsrBloc bloc) => bloc.add(
        PillarDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      expect: () => <Matcher>[
        isA<PillarDepositQsrLoading>(),
        isA<PillarDepositQsrFailure>().having(
          (PillarDepositQsrFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
