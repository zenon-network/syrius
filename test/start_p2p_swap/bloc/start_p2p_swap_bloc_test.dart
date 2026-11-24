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

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockLedger extends Mock implements LedgerApi {}

class MockMomentum extends Mock implements Momentum {}

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
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(FakeHtlcSwap());
  });

  group('StartP2pSwapBloc', () {
    const Duration expirationDuration = kInitialHtlcDuration;
    const int frontierTimestamp = 1000;
    final BigInt fromAmount = BigInt.one;
    final Address selfAddress = emptyAddress;
    final Address counterpartyAddress = emptyAddress;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockHtlcApi htlcApi;
    late MockLedger ledger;
    late MockMomentum momentum;
    late MockAccountBlockUtils accountBlockUtils;
    late MockP2pSwapRepository swapRepository;
    late MockZenonAddressUtils zenonAddressUtils;
    late AccountBlockTemplate transactionParams;
    late AccountBlockTemplate response;
    late StartP2pSwapBloc bloc;
    late BlocObserver previousObserver;
    late _RecordingBlocObserver observer;

    StartP2pSwapRequested buildEvent() => StartP2pSwapRequested(
      selfAddress: selfAddress,
      counterpartyAddress: counterpartyAddress,
      fromToken: kZnnCoin,
      fromAmount: fromAmount,
    );

    setUp(() {
      previousObserver = Bloc.observer;
      observer = _RecordingBlocObserver();
      Bloc.observer = observer;
      zenon = MockZenon();
      embedded = MockEmbedded();
      htlcApi = MockHtlcApi();
      ledger = MockLedger();
      momentum = MockMomentum();
      accountBlockUtils = MockAccountBlockUtils();
      swapRepository = MockP2pSwapRepository();
      zenonAddressUtils = MockZenonAddressUtils();
      transactionParams = AccountBlockTemplate(blockType: 1);
      response = AccountBlockTemplate(blockType: 1)
        ..hash = Hash.digest(<int>[1, 2, 3])
        ..chainIdentifier = 7;

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.htlc).thenReturn(htlcApi);
      when(() => zenon.ledger).thenReturn(ledger);
      when(
        () => ledger.getFrontierMomentum(),
      ).thenAnswer((_) async => momentum);
      when(() => momentum.timestamp).thenReturn(frontierTimestamp);
      when(
        () => htlcApi.create(
          kZnnCoin,
          fromAmount,
          counterpartyAddress,
          frontierTimestamp + expirationDuration.inSeconds,
          htlcHashTypeSha3,
          htlcPreimageMaxLength,
          any(),
        ),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'start swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => response);
      when(() => swapRepository.storeSwap(any())).thenAnswer((_) async {});
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = StartP2pSwapBloc(
        accountBlockUtils: accountBlockUtils,
        swapRepository: swapRepository,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    tearDown(() {
      Bloc.observer = previousObserver;
    });

    test('initial state is correct', () {
      expect(bloc.state, const StartP2pSwapInitial());
    });

    blocTest<StartP2pSwapBloc, StartP2pSwapState>(
      'creates, stores, and emits the outgoing HTLC swap',
      build: () => bloc,
      act: (StartP2pSwapBloc bloc) => bloc.add(buildEvent()),
      verify: (_) {
        verify(
          () => htlcApi.create(
            kZnnCoin,
            fromAmount,
            counterpartyAddress,
            frontierTimestamp + expirationDuration.inSeconds,
            htlcHashTypeSha3,
            htlcPreimageMaxLength,
            any(),
          ),
        ).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'start swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);

        final HtlcSwap swap =
            verify(() => swapRepository.storeSwap(captureAny())).captured.single
                as HtlcSwap;
        final List<int> preimage = FormatUtils.decodeHexString(swap.preimage!);

        expect(swap.id, response.hash.toString());
        expect(swap.chainId, response.chainIdentifier);
        expect(swap.initialHtlcId, response.hash.toString());
        expect(
          swap.initialHtlcExpirationTime,
          frontierTimestamp + expirationDuration.inSeconds,
        );
        expect(swap.direction, P2pSwapDirection.outgoing);
        expect(swap.state, P2pSwapState.pending);
        expect(swap.fromAmount, fromAmount);
        expect(swap.fromToken, kZnnCoin);
        expect(preimage, hasLength(htlcPreimageDefaultLength));
        expect(swap.hashLock, Hash.digest(preimage).toString());
      },
      expect: () => <Matcher>[
        isA<StartP2pSwapLoading>(),
        isA<StartP2pSwapDone>(),
      ],
    );

    blocTest<StartP2pSwapBloc, StartP2pSwapState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'start swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (StartP2pSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<StartP2pSwapLoading>(),
        isA<StartP2pSwapFailure>().having(
          (StartP2pSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<StartP2pSwapBloc, StartP2pSwapState>(
      'emits [loading, failure] on generic exception',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'start swap',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (StartP2pSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<StartP2pSwapLoading>(),
        isA<StartP2pSwapFailure>().having(
          (StartP2pSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        expect(observer.errors, hasLength(1));
        expect(observer.errors.single, isA<RedactedSwapError>());
      },
    );

    String? capturedPreimage;
    blocTest<StartP2pSwapBloc, StartP2pSwapState>(
      'redacts storage exceptions on storeSwap so preimage is never logged',
      setUp: () {
        capturedPreimage = null;
        when(() => swapRepository.storeSwap(any())).thenAnswer((
          Invocation invocation,
        ) async {
          final HtlcSwap stored =
              invocation.positionalArguments.first as HtlcSwap;
          capturedPreimage = stored.preimage;
          throw DriftWrappedException(
            message: 'insert failed: ${stored.preimage}',
            cause: SqliteException(
              extendedResultCode: 13,
              message: 'database or disk is full',
              causingStatement: 'INSERT INTO htlc_swaps VALUES (?)',
              parametersToStatement: <Object?>[
                '{"preimage":"${stored.preimage}"}',
              ],
            ),
          );
        });
      },
      build: () => bloc,
      act: (StartP2pSwapBloc bloc) => bloc.add(buildEvent()),
      expect: () => <Matcher>[
        isA<StartP2pSwapLoading>(),
        isA<StartP2pSwapFailure>().having(
          (StartP2pSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => zenonAddressUtils.refreshBalance());
        expect(capturedPreimage, isNotNull);
        expect(observer.errors, hasLength(1));
        expect(observer.errors.single, isA<RedactedSwapError>());
        expect(
          observer.errors.single.toString(),
          'DriftWrappedException -> SqliteException (code=13)',
        );
        expect(
          observer.errors.single.toString(),
          isNot(contains(capturedPreimage)),
        );
      },
    );
  });
}
