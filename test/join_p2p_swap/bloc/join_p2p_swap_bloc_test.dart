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

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

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
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(FakeHtlcSwap());
  });

  group('JoinP2pSwapBloc', () {
    const int now = 1000;
    const int counterHtlcExpirationTime = now + Duration.secondsPerHour;
    final BigInt fromAmount = BigInt.from(10);
    final Hash initialHtlcId = Hash.digest(<int>[1, 2, 3]);
    final Address selfAddress = emptyAddress;
    final Address counterpartyAddress = htlcAddress;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockHtlcApi htlcApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockP2pSwapRepository swapRepository;
    late MockZenonAddressUtils zenonAddressUtils;
    late HtlcInfo initialHtlc;
    late AccountBlockTemplate transactionParams;
    late AccountBlockTemplate response;
    late JoinP2pSwapBloc bloc;
    late BlocObserver previousObserver;
    late _RecordingBlocObserver observer;

    JoinP2pSwapRequested buildEvent() => JoinP2pSwapRequested(
      initialHtlc: initialHtlc,
      fromToken: kZnnCoin,
      toToken: kQsrCoin,
      fromAmount: fromAmount,
      swapType: P2pSwapType.native,
      fromChain: P2pSwapChain.nom,
      toChain: P2pSwapChain.nom,
    );

    HtlcInfo buildInitialHtlc(int expirationTime) => HtlcInfo(
      id: initialHtlcId,
      timeLocked: counterpartyAddress,
      hashLocked: selfAddress,
      tokenStandard: kQsrCoin.tokenStandard,
      amount: BigInt.from(20),
      expirationTime: expirationTime,
      hashType: htlcHashTypeSha3,
      keyMaxSize: htlcPreimageMaxLength,
      hashLock: <int>[4, 5, 6],
    );

    setUp(() {
      previousObserver = Bloc.observer;
      observer = _RecordingBlocObserver();
      Bloc.observer = observer;
      zenon = MockZenon();
      embedded = MockEmbedded();
      htlcApi = MockHtlcApi();
      accountBlockUtils = MockAccountBlockUtils();
      swapRepository = MockP2pSwapRepository();
      zenonAddressUtils = MockZenonAddressUtils();
      initialHtlc = buildInitialHtlc(now + kInitialHtlcDuration.inSeconds);
      transactionParams = AccountBlockTemplate(blockType: 1);
      response = AccountBlockTemplate(blockType: 1)
        ..hash = Hash.digest(<int>[7, 8, 9])
        ..chainIdentifier = 7;

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.htlc).thenReturn(htlcApi);
      when(
        () => htlcApi.create(
          kZnnCoin,
          fromAmount,
          counterpartyAddress,
          counterHtlcExpirationTime,
          htlcHashTypeSha3,
          htlcPreimageMaxLength,
          initialHtlc.hashLock,
        ),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'join swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => response);
      when(() => swapRepository.storeSwap(any())).thenAnswer((_) async {});
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = JoinP2pSwapBloc(
        accountBlockUtils: accountBlockUtils,
        swapRepository: swapRepository,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
        unixTimeProvider: () => now,
      );
    });

    tearDown(() {
      Bloc.observer = previousObserver;
    });

    test('initial state is correct', () {
      expect(bloc.state, const JoinP2pSwapInitial());
    });

    blocTest<JoinP2pSwapBloc, JoinP2pSwapState>(
      'creates, stores, and emits the incoming HTLC swap',
      build: () => bloc,
      act: (JoinP2pSwapBloc bloc) => bloc.add(buildEvent()),
      verify: (_) {
        verify(
          () => htlcApi.create(
            kZnnCoin,
            fromAmount,
            counterpartyAddress,
            counterHtlcExpirationTime,
            htlcHashTypeSha3,
            htlcPreimageMaxLength,
            initialHtlc.hashLock,
          ),
        ).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'join swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);

        final HtlcSwap swap =
            verify(() => swapRepository.storeSwap(captureAny())).captured.single
                as HtlcSwap;

        expect(swap.id, initialHtlcId.toString());
        expect(swap.chainId, response.chainIdentifier);
        expect(swap.direction, P2pSwapDirection.incoming);
        expect(swap.state, P2pSwapState.active);
        expect(swap.selfAddress, selfAddress.toString());
        expect(swap.counterpartyAddress, counterpartyAddress.toString());
        expect(swap.initialHtlcId, initialHtlcId.toString());
        expect(swap.counterHtlcId, response.hash.toString());
        expect(swap.counterHtlcExpirationTime, counterHtlcExpirationTime);
        expect(swap.fromAmount, fromAmount);
        expect(swap.fromToken, kZnnCoin);
        expect(swap.toAmount, initialHtlc.amount);
        expect(swap.toToken, kQsrCoin);
        expect(
          swap.hashLock,
          FormatUtils.encodeHexString(initialHtlc.hashLock),
        );
      },
      expect: () => <Matcher>[
        isA<JoinP2pSwapLoading>(),
        isA<JoinP2pSwapDone>(),
      ],
    );

    blocTest<JoinP2pSwapBloc, JoinP2pSwapState>(
      'rejects a join request after the safe cutoff',
      setUp: () {
        initialHtlc = buildInitialHtlc(
          now +
              kMinSafeTimeToFindPreimage.inSeconds +
              kCounterHtlcDuration.inSeconds -
              1,
        );
      },
      build: () => bloc,
      act: (JoinP2pSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<JoinP2pSwapFailure>().having(
          (JoinP2pSwapFailure state) => state.exception.message,
          'message',
          'This deposit will expire too soon for a safe swap.',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => htlcApi.create(
            kZnnCoin,
            fromAmount,
            counterpartyAddress,
            counterHtlcExpirationTime,
            htlcHashTypeSha3,
            htlcPreimageMaxLength,
            initialHtlc.hashLock,
          ),
        );
      },
    );

    blocTest<JoinP2pSwapBloc, JoinP2pSwapState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'join swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (JoinP2pSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<JoinP2pSwapLoading>(),
        isA<JoinP2pSwapFailure>().having(
          (JoinP2pSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<JoinP2pSwapBloc, JoinP2pSwapState>(
      'emits [loading, failure] on generic error',
      setUp: () {
        when(
          () => swapRepository.storeSwap(any()),
        ).thenThrow(StateError('boom'));
      },
      build: () => bloc,
      act: (JoinP2pSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<JoinP2pSwapLoading>(),
        isA<JoinP2pSwapFailure>().having(
          (JoinP2pSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => zenonAddressUtils.refreshBalance());
        expect(observer.errors, hasLength(1));
        expect(observer.errors.single, isA<RedactedSwapError>());
        expect(observer.errors.single.toString(), 'StateError');
      },
    );

    blocTest<JoinP2pSwapBloc, JoinP2pSwapState>(
      'redacts Drift/SQLite storage exceptions on storeSwap',
      setUp: () {
        when(() => swapRepository.storeSwap(any())).thenThrow(
          DriftWrappedException(
            message: 'insert failed with payloadJson',
            cause: SqliteException(
              extendedResultCode: 13,
              message: 'database or disk is full',
              causingStatement: 'INSERT INTO htlc_swaps VALUES (?)',
              parametersToStatement: <Object?>['sensitive-payload-json'],
            ),
          ),
        );
      },
      build: () => bloc,
      act: (JoinP2pSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<JoinP2pSwapLoading>(),
        isA<JoinP2pSwapFailure>().having(
          (JoinP2pSwapFailure state) => state.exception,
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
          isNot(contains('sensitive-payload-json')),
        );
      },
    );
  });
}
