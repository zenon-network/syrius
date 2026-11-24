import 'dart:async';

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

    SentinelDepositQsrBloc buildBloc({
      Duration pollInterval = Duration.zero,
      Duration confirmationTimeout = const Duration(milliseconds: 50),
      Duration postTransactionDelay = Duration.zero,
    }) => SentinelDepositQsrBloc(
      accountBlockUtils: accountBlockUtils,
      zenon: zenon,
      zenonAddressUtils: zenonAddressUtils,
      pollInterval: pollInterval,
      confirmationTimeout: confirmationTimeout,
      postTransactionDelay: postTransactionDelay,
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
      when(() => sentinelApi.depositQsr(any())).thenReturn(template);
      when(
        () => sentinelApi.getDepositedQsr(any()),
      ).thenAnswer((_) async => BigInt.zero);
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
      expect(bloc.state, const SentinelDepositQsrInitial());
    });

    blocTest<SentinelDepositQsrBloc, SentinelDepositQsrState>(
      'polls getDepositedQsr across retries and transient errors until '
      'deposit is confirmed',
      setUp: () {
        int calls = 0;
        when(() => sentinelApi.getDepositedQsr(emptyAddress)).thenAnswer((
          _,
        ) async {
          calls += 1;
          if (calls == 1) {
            return BigInt.from(100);
          }
          if (calls == 2) {
            return BigInt.from(100);
          }
          if (calls == 3) {
            throw Exception('transient RPC error');
          }
          return BigInt.from(150);
        });
      },
      build: buildBloc,
      act: (SentinelDepositQsrBloc bloc) => bloc.add(
        SentinelDepositQsrRequested(
          address: emptyAddress,
          amount: BigInt.from(50),
        ),
      ),
      wait: const Duration(milliseconds: 50),
      expect: () => <SentinelDepositQsrState>[
        const SentinelDepositQsrLoading(),
        const SentinelDepositQsrDone(),
      ],
      verify: (_) {
        verify(() => sentinelApi.getDepositedQsr(emptyAddress)).called(4);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SentinelDepositQsrBloc, SentinelDepositQsrState>(
      'still emits done and refreshes balance when confirmation polling '
      'times out',
      build: () => buildBloc(confirmationTimeout: Duration.zero),
      act: (SentinelDepositQsrBloc bloc) => bloc.add(
        SentinelDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      wait: const Duration(milliseconds: 50),
      expect: () => <SentinelDepositQsrState>[
        const SentinelDepositQsrLoading(),
        const SentinelDepositQsrDone(),
      ],
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<SentinelDepositQsrBloc, SentinelDepositQsrState>(
      'falls back to postTransactionDelay when initial deposit snapshot fails',
      setUp: () {
        when(
          () => sentinelApi.getDepositedQsr(emptyAddress),
        ).thenThrow(Exception('snapshot failed'));
      },
      build: buildBloc,
      act: (SentinelDepositQsrBloc bloc) => bloc.add(
        SentinelDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      wait: const Duration(milliseconds: 50),
      expect: () => <SentinelDepositQsrState>[
        const SentinelDepositQsrLoading(),
        const SentinelDepositQsrDone(),
      ],
      verify: (_) {
        verify(() => sentinelApi.getDepositedQsr(emptyAddress)).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    test('stops polling cleanly when closed before confirmation', () async {
      final Completer<void> firstPollStarted = Completer<void>();
      int calls = 0;
      when(() => sentinelApi.getDepositedQsr(emptyAddress)).thenAnswer((
        _,
      ) async {
        calls += 1;
        if (calls == 2 && !firstPollStarted.isCompleted) {
          firstPollStarted.complete();
        }
        return BigInt.zero;
      });

      final SentinelDepositQsrBloc closingBloc =
          buildBloc(
            pollInterval: const Duration(milliseconds: 5),
            confirmationTimeout: const Duration(seconds: 5),
          )..add(
            SentinelDepositQsrRequested(
              address: emptyAddress,
              amount: BigInt.one,
            ),
          );

      await firstPollStarted.future;
      await closingBloc.close();

      final int callsAfterClose = calls;
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(calls, callsAfterClose);
      verifyNever(() => zenonAddressUtils.refreshBalance());
    });

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
