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
  });

  group('PillarWithdrawQsrBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPillarApi pillarApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late PillarWithdrawQsrBloc bloc;
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
      when(() => pillarApi.withdrawQsr()).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = PillarWithdrawQsrBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
        postTransactionDelay: Duration.zero,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const PillarWithdrawQsrInitial());
    });

    blocTest<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      'emits [loading, populated] on success',
      build: () => bloc,
      act: (PillarWithdrawQsrBloc bloc) =>
          bloc.add(PillarWithdrawQsrRequested(address: emptyAddress)),
      wait: const Duration(milliseconds: 1),
      expect: () => <PillarWithdrawQsrState>[
        const PillarWithdrawQsrLoading(),
        const PillarWithdrawQsrPopulated(),
      ],
    );

    blocTest<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => pillarApi.withdrawQsr()).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (PillarWithdrawQsrBloc bloc) =>
          bloc.add(PillarWithdrawQsrRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<PillarWithdrawQsrLoading>(),
        isA<PillarWithdrawQsrFailure>().having(
          (PillarWithdrawQsrFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
