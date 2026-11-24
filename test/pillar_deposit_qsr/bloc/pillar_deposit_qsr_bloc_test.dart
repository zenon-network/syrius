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

    PillarDepositQsrBloc buildBloc({
      Duration pollInterval = Duration.zero,
      Duration confirmationTimeout = const Duration(seconds: 5),
      Duration snapshotReadTimeout = const Duration(seconds: 5),
      Duration postTransactionDelay = Duration.zero,
    }) => PillarDepositQsrBloc(
      accountBlockUtils: accountBlockUtils,
      zenon: zenon,
      zenonAddressUtils: zenonAddressUtils,
      pollInterval: pollInterval,
      confirmationTimeout: confirmationTimeout,
      snapshotReadTimeout: snapshotReadTimeout,
      postTransactionDelay: postTransactionDelay,
    );

    Future<void> dispatchAndWaitForCompletion(
      PillarDepositQsrBloc target,
      PillarDepositQsrRequested event,
    ) async {
      final Future<PillarDepositQsrState> completed = target.stream
          .firstWhere(
            (PillarDepositQsrState state) =>
                state is PillarDepositQsrDone ||
                state is PillarDepositQsrFailure,
          )
          .timeout(const Duration(seconds: 2));
      target.add(event);
      await completed;
    }

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
        () => pillarApi.getDepositedQsr(any()),
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
      expect(bloc.state, const PillarDepositQsrInitial());
    });

    blocTest<PillarDepositQsrBloc, PillarDepositQsrState>(
      'polls getDepositedQsr across retries and transient errors until '
      'deposit is confirmed',
      setUp: () {
        int calls = 0;
        when(() => pillarApi.getDepositedQsr(emptyAddress)).thenAnswer((
          _,
        ) async {
          calls += 1;
          if (calls == 1) {
            return BigInt.from(200);
          }
          if (calls == 2) {
            return BigInt.from(200);
          }
          if (calls == 3) {
            throw Exception('transient RPC error');
          }
          return BigInt.from(300);
        });
      },
      build: buildBloc,
      act: (PillarDepositQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarDepositQsrRequested(
          address: emptyAddress,
          amount: BigInt.from(100),
        ),
      ),
      expect: () => <PillarDepositQsrState>[
        const PillarDepositQsrLoading(),
        PillarDepositQsrDone(accountBlock: template),
      ],
      verify: (_) {
        verify(() => pillarApi.getDepositedQsr(emptyAddress)).called(4);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<PillarDepositQsrBloc, PillarDepositQsrState>(
      'still emits done and refreshes balance when confirmation polling '
      'times out',
      build: () => buildBloc(confirmationTimeout: Duration.zero),
      act: (PillarDepositQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      expect: () => <PillarDepositQsrState>[
        const PillarDepositQsrLoading(),
        PillarDepositQsrDone(accountBlock: template),
      ],
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<PillarDepositQsrBloc, PillarDepositQsrState>(
      'falls back to postTransactionDelay when initial deposit snapshot fails',
      setUp: () {
        when(
          () => pillarApi.getDepositedQsr(emptyAddress),
        ).thenThrow(Exception('snapshot failed'));
      },
      build: buildBloc,
      act: (PillarDepositQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      expect: () => <PillarDepositQsrState>[
        const PillarDepositQsrLoading(),
        PillarDepositQsrDone(accountBlock: template),
      ],
      verify: (_) {
        verify(() => pillarApi.getDepositedQsr(emptyAddress)).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<PillarDepositQsrBloc, PillarDepositQsrState>(
      'falls back to postTransactionDelay when initial deposit snapshot times '
      'out',
      setUp: () {
        final Completer<BigInt> stalledSnapshot = Completer<BigInt>();
        when(
          () => pillarApi.getDepositedQsr(emptyAddress),
        ).thenAnswer((_) => stalledSnapshot.future);
      },
      build: () => buildBloc(
        snapshotReadTimeout: const Duration(milliseconds: 10),
      ),
      act: (PillarDepositQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarDepositQsrRequested(address: emptyAddress, amount: BigInt.one),
      ),
      expect: () => <PillarDepositQsrState>[
        const PillarDepositQsrLoading(),
        PillarDepositQsrDone(accountBlock: template),
      ],
      verify: (_) {
        verify(() => pillarApi.getDepositedQsr(emptyAddress)).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
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
