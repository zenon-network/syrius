import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockHtlcSwapUnlockService extends Mock implements HtlcSwapUnlockService {}

class MockP2pSwapRepository extends Mock
    implements P2pSwapRepository<HtlcSwap> {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class FakeHtlcSwap extends Fake implements HtlcSwap {}

class _RecordingBlocObserver extends BlocObserver {
  final List<Object> errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeHtlcSwap());
  });

  group('CompleteSwapBloc', () {
    final Hash initialHtlcId = Hash.digest(<int>[1, 2, 3]);
    final Hash counterHtlcId = Hash.digest(<int>[4, 5, 6]);
    final Address selfAddress = emptyAddress;

    late MockHtlcSwapUnlockService unlockService;
    late MockP2pSwapRepository swapRepository;
    late MockZenonAddressUtils zenonAddressUtils;
    late AccountBlockTemplate block;
    late HtlcSwap swap;
    late CompleteSwapBloc bloc;
    late BlocObserver previousObserver;
    late _RecordingBlocObserver observer;

    setUp(() {
      previousObserver = Bloc.observer;
      observer = _RecordingBlocObserver();
      Bloc.observer = observer;
      unlockService = MockHtlcSwapUnlockService();
      swapRepository = MockP2pSwapRepository();
      zenonAddressUtils = MockZenonAddressUtils();
      block = AccountBlockTemplate(blockType: 1);
      swap = HtlcSwap(
        hashLock: Hash.digest(<int>[7, 8, 9]).toString(),
        initialHtlcId: initialHtlcId.toString(),
        initialHtlcExpirationTime: 2000,
        hashType: htlcHashTypeSha3,
        id: initialHtlcId.toString(),
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.outgoing,
        selfAddress: selfAddress.toString(),
        counterpartyAddress: htlcAddress.toString(),
        fromAmount: BigInt.one,
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: 1000,
        state: P2pSwapState.active,
        counterHtlcId: counterHtlcId.toString(),
        preimage: FormatUtils.encodeHexString(<int>[7, 8, 9]),
      );

      when(() => unlockService.unlock(swap)).thenAnswer((_) async => block);
      when(() => swapRepository.storeSwap(any())).thenAnswer((_) async {});
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = CompleteSwapBloc(
        htlcSwapUnlockService: unlockService,
        swapRepository: swapRepository,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    tearDown(() {
      Bloc.observer = previousObserver;
    });

    test('initial state is correct', () {
      expect(bloc.state, const CompleteSwapInitial());
    });

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'unlocks the swap, stores it as completed, and refreshes balances',
      build: () => bloc,
      act: (CompleteSwapBloc bloc) =>
          bloc.add(CompleteSwapRequested(swap: swap)),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapDone>()
            .having(
              (CompleteSwapDone state) => state.block,
              'submitted block',
              block,
            )
            .having(
              (CompleteSwapDone state) => state.swap.state,
              'swap state',
              P2pSwapState.completed,
            ),
      ],
      verify: (_) {
        verify(() => unlockService.unlock(swap)).called(1);
        final HtlcSwap storedSwap =
            verify(() => swapRepository.storeSwap(captureAny())).captured.single
                as HtlcSwap;
        expect(storedSwap.state, P2pSwapState.completed);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'preserves a SyriusException from the unlock service',
      setUp: () {
        when(
          () => unlockService.unlock(swap),
        ).thenThrow(SyriusException('Unable to complete swap.'));
      },
      build: () => bloc,
      act: (CompleteSwapBloc bloc) =>
          bloc.add(CompleteSwapRequested(swap: swap)),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapFailure>().having(
          (CompleteSwapFailure state) => state.exception.message,
          'message',
          'Unable to complete swap.',
        ),
      ],
      verify: (_) {
        verifyNever(() => swapRepository.storeSwap(any()));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'converts an unexpected error to FailureException',
      setUp: () {
        when(() => unlockService.unlock(swap)).thenThrow(StateError('boom'));
      },
      build: () => bloc,
      act: (CompleteSwapBloc bloc) =>
          bloc.add(CompleteSwapRequested(swap: swap)),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapFailure>().having(
          (CompleteSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => swapRepository.storeSwap(any()));
        verifyNever(() => zenonAddressUtils.refreshBalance());
        expect(observer.errors, hasLength(1));
        expect(observer.errors.single, isA<RedactedSwapError>());
        expect(observer.errors.single.toString(), 'StateError');
      },
    );

    blocTest<CompleteSwapBloc, CompleteSwapState>(
      'redacts storage exceptions so swap preimage is never logged',
      setUp: () {
        when(() => swapRepository.storeSwap(any())).thenThrow(
          DriftWrappedException(
            message: 'write failed for ${swap.preimage}',
            cause: SqliteException(
              extendedResultCode: 13,
              message: 'database or disk is full',
              causingStatement: 'INSERT INTO htlc_swaps VALUES (?)',
              parametersToStatement: <Object?>[
                '{"preimage":"${swap.preimage}"}',
              ],
            ),
          ),
        );
      },
      build: () => bloc,
      act: (CompleteSwapBloc bloc) =>
          bloc.add(CompleteSwapRequested(swap: swap)),
      expect: () => <Matcher>[
        isA<CompleteSwapLoading>(),
        isA<CompleteSwapFailure>().having(
          (CompleteSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => zenonAddressUtils.refreshBalance());
        expect(observer.errors, hasLength(1));
        expect(observer.errors.single, isA<RedactedSwapError>());
        expect(
          observer.errors.single.toString(),
          'DriftWrappedException -> SqliteException (code=13)',
        );
        expect(
          observer.errors.single.toString(),
          isNot(contains(swap.preimage)),
        );
      },
    );
  });
}
