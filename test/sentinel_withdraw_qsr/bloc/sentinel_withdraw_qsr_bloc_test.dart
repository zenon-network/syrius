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
  });

  group('SentinelWithdrawQsrBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockSentinelApi sentinelApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late SentinelWithdrawQsrBloc bloc;
    late AccountBlockTemplate template;

    SentinelWithdrawQsrBloc buildBloc({
      Duration pollInterval = Duration.zero,
      Duration confirmationTimeout = const Duration(milliseconds: 50),
    }) => SentinelWithdrawQsrBloc(
      accountBlockUtils: accountBlockUtils,
      zenon: zenon,
      zenonAddressUtils: zenonAddressUtils,
      pollInterval: pollInterval,
      confirmationTimeout: confirmationTimeout,
    );

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      sentinelApi = MockSentinelApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.sentinel).thenReturn(sentinelApi);
      when(() => sentinelApi.withdrawQsr()).thenReturn(template);
      when(
        () => sentinelApi.getDepositedQsr(any()),
      ).thenAnswer((_) async => BigInt.from(5000));
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = buildBloc();
    });

    test('initial state is correct', () {
      expect(bloc.state, const SentinelWithdrawQsrInitial());
    });

    blocTest<SentinelWithdrawQsrBloc, SentinelWithdrawQsrState>(
      'polls getDepositedQsr until withdrawn deposit decreases',
      setUp: () {
        int calls = 0;
        when(() => sentinelApi.getDepositedQsr(emptyAddress)).thenAnswer((
          _,
        ) async {
          calls += 1;
          if (calls <= 2) {
            return BigInt.from(5000);
          }
          if (calls == 3) {
            throw Exception('transient RPC error');
          }
          return BigInt.zero;
        });
      },
      build: buildBloc,
      act: (SentinelWithdrawQsrBloc bloc) =>
          bloc.add(SentinelWithdrawQsrRequested(address: emptyAddress)),
      wait: const Duration(milliseconds: 50),
      expect: () => <SentinelWithdrawQsrState>[
        const SentinelWithdrawQsrLoading(),
        const SentinelWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => sentinelApi.getDepositedQsr(emptyAddress)).called(4);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SentinelWithdrawQsrBloc, SentinelWithdrawQsrState>(
      'polls until deposit reaches zero when initial snapshot fails',
      setUp: () {
        int calls = 0;
        when(() => sentinelApi.getDepositedQsr(emptyAddress)).thenAnswer((
          _,
        ) async {
          calls += 1;
          if (calls == 1) {
            throw Exception('snapshot failed');
          }
          if (calls == 2) {
            return BigInt.from(5000);
          }
          return BigInt.zero;
        });
      },
      build: buildBloc,
      act: (SentinelWithdrawQsrBloc bloc) =>
          bloc.add(SentinelWithdrawQsrRequested(address: emptyAddress)),
      wait: const Duration(milliseconds: 50),
      expect: () => <SentinelWithdrawQsrState>[
        const SentinelWithdrawQsrLoading(),
        const SentinelWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => sentinelApi.getDepositedQsr(emptyAddress)).called(3);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SentinelWithdrawQsrBloc, SentinelWithdrawQsrState>(
      'skips confirmation polling when initial deposit is zero',
      setUp: () {
        when(
          () => sentinelApi.getDepositedQsr(emptyAddress),
        ).thenAnswer((_) async => BigInt.zero);
      },
      build: buildBloc,
      act: (SentinelWithdrawQsrBloc bloc) =>
          bloc.add(SentinelWithdrawQsrRequested(address: emptyAddress)),
      wait: const Duration(milliseconds: 50),
      expect: () => <SentinelWithdrawQsrState>[
        const SentinelWithdrawQsrLoading(),
        const SentinelWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => sentinelApi.getDepositedQsr(emptyAddress)).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SentinelWithdrawQsrBloc, SentinelWithdrawQsrState>(
      'still emits populated when confirmation polling times out',
      build: () => buildBloc(confirmationTimeout: Duration.zero),
      act: (SentinelWithdrawQsrBloc bloc) =>
          bloc.add(SentinelWithdrawQsrRequested(address: emptyAddress)),
      wait: const Duration(milliseconds: 50),
      expect: () => <SentinelWithdrawQsrState>[
        const SentinelWithdrawQsrLoading(),
        const SentinelWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SentinelWithdrawQsrBloc, SentinelWithdrawQsrState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => sentinelApi.withdrawQsr()).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (SentinelWithdrawQsrBloc bloc) =>
          bloc.add(SentinelWithdrawQsrRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<SentinelWithdrawQsrLoading>(),
        isA<SentinelWithdrawQsrFailure>().having(
          (SentinelWithdrawQsrFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
