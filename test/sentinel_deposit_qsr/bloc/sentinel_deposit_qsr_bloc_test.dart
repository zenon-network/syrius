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

class MockSentinelApi extends Mock implements SentinelApi {}

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

  group('SentinelDepositQsrBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockSentinelApi sentinelApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late SentinelDepositQsrBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      sentinelApi = MockSentinelApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.sentinel).thenReturn(sentinelApi);
      when(() => sentinelApi.depositQsr(any())).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = SentinelDepositQsrBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
        postTransactionDelay: Duration.zero,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const SentinelDepositQsrInitial());
    });

    blocTest<SentinelDepositQsrBloc, SentinelDepositQsrState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (SentinelDepositQsrBloc bloc) => bloc.add(
        SentinelDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      wait: const Duration(milliseconds: 1),
      expect: () => <SentinelDepositQsrState>[
        const SentinelDepositQsrLoading(),
        const SentinelDepositQsrDone(),
      ],
    );

    blocTest<SentinelDepositQsrBloc, SentinelDepositQsrState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => sentinelApi.depositQsr(any())).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (SentinelDepositQsrBloc bloc) => bloc.add(
        SentinelDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      expect: () => <Matcher>[
        isA<SentinelDepositQsrLoading>(),
        isA<SentinelDepositQsrFailure>().having(
          (SentinelDepositQsrFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
