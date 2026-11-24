import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockP2pSwapRepository extends Mock
    implements P2pSwapRepository<HtlcSwap> {}

class _RecordingBlocObserver extends BlocObserver {
  final List<Object> errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  group('P2pSwapBloc', () {
    const String swapId = 'swap-id';

    late MockP2pSwapRepository swapRepository;
    late HtlcSwap swap;

    P2pSwapBloc buildBloc({
      Duration refreshInterval = const Duration(minutes: 1),
    }) {
      return P2pSwapBloc(
        swapRepository: swapRepository,
        refreshInterval: refreshInterval,
        swapId: swapId,
      );
    }

    setUp(() {
      swapRepository = MockP2pSwapRepository();
      swap = HtlcSwap(
        hashLock: 'hash-lock',
        initialHtlcId: 'initial-htlc-id',
        initialHtlcExpirationTime: 100,
        hashType: htlcHashTypeSha3,
        id: swapId,
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.outgoing,
        selfAddress: 'self-address',
        counterpartyAddress: 'counterparty-address',
        fromAmount: BigInt.one,
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: 1,
        state: P2pSwapState.pending,
      );

      when(
        () => swapRepository.getSwapById(swapId),
      ).thenAnswer((_) async => swap);
    });

    test('initial state is P2pSwapInitial', () {
      final P2pSwapBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const P2pSwapInitial());
    });

    blocTest<P2pSwapBloc, P2pSwapBlocState>(
      'fetches the swap and emits loading and populated states',
      build: buildBloc,
      act: (P2pSwapBloc bloc) => bloc.add(const P2pSwapRequested()),
      verify: (_) {
        verify(() => swapRepository.getSwapById(swapId)).called(1);
      },
      expect: () => <P2pSwapBlocState>[
        const P2pSwapLoading(),
        P2pSwapPopulated(swap: swap),
      ],
    );

    blocTest<P2pSwapBloc, P2pSwapBlocState>(
      'emits failure when the swap does not exist',
      setUp: () {
        when(
          () => swapRepository.getSwapById(swapId),
        ).thenAnswer((_) async => null);
      },
      build: buildBloc,
      act: (P2pSwapBloc bloc) => bloc.add(const P2pSwapRequested()),
      expect: () => <Object>[
        const P2pSwapLoading(),
        isA<P2pSwapFailure>().having(
          (P2pSwapFailure state) => state.exception.message,
          'message',
          'Swap does not exist',
        ),
      ],
    );

    blocTest<P2pSwapBloc, P2pSwapBlocState>(
      'emits generic failure when fetching throws unexpectedly',
      setUp: () {
        when(
          () => swapRepository.getSwapById(swapId),
        ).thenThrow(Exception('boom'));
      },
      build: buildBloc,
      act: (P2pSwapBloc bloc) => bloc.add(const P2pSwapRequested()),
      expect: () => <Object>[
        const P2pSwapLoading(),
        isA<P2pSwapFailure>().having(
          (P2pSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<P2pSwapBloc, P2pSwapBlocState>(
      'periodically refreshes after the initial request',
      build: () => buildBloc(refreshInterval: const Duration(milliseconds: 10)),
      act: (P2pSwapBloc bloc) => bloc.add(const P2pSwapRequested()),
      wait: const Duration(milliseconds: 25),
      verify: (_) {
        verify(
          () => swapRepository.getSwapById(swapId),
        ).called(greaterThanOrEqualTo(2));
      },
    );

    test('cancels periodic refreshes when closed', () async {
      final P2pSwapBloc bloc = buildBloc(
        refreshInterval: const Duration(milliseconds: 10),
      )..add(const P2pSwapRequested());

      await expectLater(bloc.stream, emitsThrough(isA<P2pSwapPopulated>()));

      await bloc.close();
      clearInteractions(swapRepository);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      verifyNever(() => swapRepository.getSwapById(swapId));
    });

    test('sanitizes preimage-bearing FormatException before reporting to '
        'BlocObserver', () async {
      const String secretPreimage = 'deadbeefcafebabe0123456789abcdef';
      final BlocObserver previousObserver = Bloc.observer;
      final _RecordingBlocObserver observer = _RecordingBlocObserver();
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = previousObserver);

      when(() => swapRepository.getSwapById(swapId)).thenThrow(
        const FormatException(
          'Unterminated string',
          '{"preimage":"$secretPreimage',
        ),
      );

      final P2pSwapBloc bloc = buildBloc()..add(const P2pSwapRequested());
      addTearDown(bloc.close);

      await expectLater(bloc.stream, emitsThrough(isA<P2pSwapFailure>()));

      expect(observer.errors, hasLength(1));
      expect(observer.errors.single, isA<RedactedSwapError>());
      expect(observer.errors.single.toString(), 'FormatException');
      expect(
        observer.errors.single.toString(),
        isNot(contains(secretPreimage)),
      );
    });
  });
}
