import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _RecordingBlocObserver extends BlocObserver {
  final List<Object> errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockTokenApi extends Mock implements TokenApi {}

class MockLedger extends Mock implements LedgerApi {}

class MockHtlcSwapRepository extends Mock implements HtlcSwapRepository {}

class MockAccountBlock extends Mock implements AccountBlock {}

class MockConfirmationDetail extends Mock
    implements AccountBlockConfirmationDetail {}

void main() {
  group('InitialHtlcValidationBloc', () {
    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final Address walletAddress = emptyAddress;
    final Address counterpartyAddress = htlcAddress;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockHtlcApi htlcApi;
    late MockTokenApi tokenApi;
    late MockLedger ledger;
    late MockHtlcSwapRepository htlcSwapRepository;
    late MockAccountBlock creationBlock;
    late MockConfirmationDetail creationConfirmation;
    late AccountInfo accountInfo;
    late HtlcInfo htlc;
    late InitialHtlcValidationBloc bloc;

    setUp(() {
      final int now = DateTime.now().unixTimestamp;
      final int expirationTime = now + const Duration(hours: 8).inSeconds;
      zenon = MockZenon();
      embedded = MockEmbedded();
      htlcApi = MockHtlcApi();
      tokenApi = MockTokenApi();
      ledger = MockLedger();
      htlcSwapRepository = MockHtlcSwapRepository();
      creationBlock = MockAccountBlock();
      creationConfirmation = MockConfirmationDetail();
      accountInfo = AccountInfo(
        address: walletAddress.toString(),
        blockCount: 0,
        balanceInfoList: const <BalanceInfoListItem>[],
      );
      htlc = HtlcInfo(
        id: htlcId,
        timeLocked: counterpartyAddress,
        hashLocked: walletAddress,
        tokenStandard: znnZts,
        amount: BigInt.one,
        expirationTime: expirationTime,
        hashType: htlcHashTypeSha3,
        keyMaxSize: htlcPreimageMaxLength,
        hashLock: <int>[4, 5, 6],
      );

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.htlc).thenReturn(htlcApi);
      when(() => embedded.token).thenReturn(tokenApi);
      when(() => zenon.ledger).thenReturn(ledger);
      when(() => htlcApi.getById(htlcId)).thenAnswer((_) async => htlc);
      when(() => tokenApi.getByZts(znnZts)).thenAnswer((_) async => kZnnCoin);
      when(
        () => htlcSwapRepository.getSwapByHtlcId(htlcId.toString()),
      ).thenAnswer((_) async => null);
      when(
        () => htlcSwapRepository.getSwapByHashLock(htlc.hashLockHex),
      ).thenAnswer((_) async => null);
      when(
        () => ledger.getAccountBlockByHash(htlcId),
      ).thenAnswer((_) async => creationBlock);
      when(
        () => ledger.getAccountInfoByAddress(walletAddress),
      ).thenAnswer((_) async => accountInfo);
      when(
        () => creationBlock.confirmationDetail,
      ).thenReturn(creationConfirmation);
      when(() => creationConfirmation.momentumTimestamp).thenReturn(now);
      bloc = InitialHtlcValidationBloc(
        accountBlocksAfterTimeFetcher: (_, _) async => <AccountBlock>[],
        htlcSwapRepository: htlcSwapRepository,
        walletAddresses: <String>{walletAddress.toString()},
        zenon: zenon,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const InitialHtlcValidationInitial());
    });

    blocTest<InitialHtlcValidationBloc, InitialHtlcValidationState>(
      'emits [loading, done] when the HTLC is valid',
      build: () => bloc,
      act: (InitialHtlcValidationBloc bloc) =>
          bloc.add(InitialHtlcValidationRequested(id: htlcId)),
      expect: () => <InitialHtlcValidationState>[
        const InitialHtlcValidationLoading(),
        InitialHtlcValidationDone(
          accountInfo: accountInfo,
          htlc: htlc,
          token: kZnnCoin,
        ),
      ],
      verify: (_) {
        verify(() => htlcApi.getById(htlcId)).called(1);
        verify(() => ledger.getAccountBlockByHash(htlcId)).called(1);
        verify(() => tokenApi.getByZts(znnZts)).called(1);
        verify(() => ledger.getAccountInfoByAddress(walletAddress)).called(1);
      },
    );

    blocTest<InitialHtlcValidationBloc, InitialHtlcValidationState>(
      'emits [loading, failure] when token information is unavailable',
      setUp: () {
        when(() => tokenApi.getByZts(znnZts)).thenAnswer((_) async => null);
      },
      build: () => bloc,
      act: (InitialHtlcValidationBloc bloc) =>
          bloc.add(InitialHtlcValidationRequested(id: htlcId)),
      expect: () => <Matcher>[
        isA<InitialHtlcValidationLoading>(),
        isA<InitialHtlcValidationFailure>().having(
          (InitialHtlcValidationFailure state) => state.exception.message,
          'message',
          'Unable to retrieve token information.',
        ),
      ],
      verify: (_) {
        verifyNever(() => ledger.getAccountInfoByAddress(walletAddress));
      },
    );

    blocTest<InitialHtlcValidationBloc, InitialHtlcValidationState>(
      'emits [loading, failure] when fetching account information fails',
      setUp: () {
        when(
          () => ledger.getAccountInfoByAddress(walletAddress),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (InitialHtlcValidationBloc bloc) =>
          bloc.add(InitialHtlcValidationRequested(id: htlcId)),
      expect: () => <Matcher>[
        isA<InitialHtlcValidationLoading>(),
        isA<InitialHtlcValidationFailure>().having(
          (InitialHtlcValidationFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<InitialHtlcValidationBloc, InitialHtlcValidationState>(
      'emits [loading, failure] when the HTLC is not intended for the wallet',
      build: () => InitialHtlcValidationBloc(
        accountBlocksAfterTimeFetcher: (_, _) async => <AccountBlock>[],
        htlcSwapRepository: htlcSwapRepository,
        walletAddresses: <String>{},
        zenon: zenon,
      ),
      act: (InitialHtlcValidationBloc bloc) =>
          bloc.add(InitialHtlcValidationRequested(id: htlcId)),
      expect: () => <Matcher>[
        isA<InitialHtlcValidationLoading>(),
        isA<InitialHtlcValidationFailure>().having(
          (InitialHtlcValidationFailure state) => state.exception.message,
          'message',
          'This deposit is not intended for you.',
        ),
      ],
      verify: (_) {
        verifyNever(() => tokenApi.getByZts(znnZts));
      },
    );

    blocTest<InitialHtlcValidationBloc, InitialHtlcValidationState>(
      'emits [loading, failure] when fetching throws unexpectedly',
      setUp: () {
        when(() => htlcApi.getById(htlcId)).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (InitialHtlcValidationBloc bloc) =>
          bloc.add(InitialHtlcValidationRequested(id: htlcId)),
      expect: () => <Matcher>[
        isA<InitialHtlcValidationLoading>(),
        isA<InitialHtlcValidationFailure>().having(
          (InitialHtlcValidationFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    test(
      'sanitizes preimage-bearing FormatException from swap repository lookups '
      'before reporting to BlocObserver',
      () async {
        const String secretPreimage = 'deadbeefcafebabe0123456789abcdef';
        final BlocObserver previousObserver = Bloc.observer;
        final _RecordingBlocObserver observer = _RecordingBlocObserver();
        Bloc.observer = observer;
        addTearDown(() => Bloc.observer = previousObserver);

        when(
          () => htlcSwapRepository.getSwapByHtlcId(htlcId.toString()),
        ).thenThrow(
          const FormatException(
            'Unexpected character',
            '{"id":"x","preimage":"$secretPreimage","state":act',
          ),
        );

        final InitialHtlcValidationBloc htlcIdBloc = InitialHtlcValidationBloc(
          accountBlocksAfterTimeFetcher: (_, _) async => <AccountBlock>[],
          htlcSwapRepository: htlcSwapRepository,
          walletAddresses: <String>{walletAddress.toString()},
          zenon: zenon,
        )..add(InitialHtlcValidationRequested(id: htlcId));
        addTearDown(htlcIdBloc.close);

        await expectLater(
          htlcIdBloc.stream,
          emitsThrough(isA<InitialHtlcValidationFailure>()),
        );

        when(
          () => htlcSwapRepository.getSwapByHtlcId(htlcId.toString()),
        ).thenAnswer((_) async => null);
        when(
          () => htlcSwapRepository.getSwapByHashLock(htlc.hashLockHex),
        ).thenThrow(
          const FormatException(
            'Unterminated string',
            '{"preimage":"$secretPreimage',
          ),
        );

        final InitialHtlcValidationBloc hashLockBloc =
            InitialHtlcValidationBloc(
              accountBlocksAfterTimeFetcher: (_, _) async => <AccountBlock>[],
              htlcSwapRepository: htlcSwapRepository,
              walletAddresses: <String>{walletAddress.toString()},
              zenon: zenon,
            )..add(InitialHtlcValidationRequested(id: htlcId));
        addTearDown(hashLockBloc.close);

        await expectLater(
          hashLockBloc.stream,
          emitsThrough(isA<InitialHtlcValidationFailure>()),
        );

        expect(observer.errors, hasLength(2));
        for (final Object error in observer.errors) {
          expect(error, isA<RedactedSwapError>());
          expect(error.toString(), 'FormatException');
          expect(error.toString(), isNot(contains(secretPreimage)));
        }
      },
    );
  });
}
