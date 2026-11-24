import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
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

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

void main() {
  group('ReclaimDepositBloc', () {
    const int now = 1000;
    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final Address selfAddress = emptyAddress;
    final Address otherAddress = htlcAddress;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockHtlcApi htlcApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late AccountBlockTemplate transactionParams;
    late HtlcInfo htlc;
    late ReclaimDepositBloc bloc;

    HtlcInfo buildHtlc({
      required Address timeLocked,
      required int expirationTime,
    }) => HtlcInfo(
      id: htlcId,
      timeLocked: timeLocked,
      hashLocked: otherAddress,
      tokenStandard: kZnnCoin.tokenStandard,
      amount: BigInt.one,
      expirationTime: expirationTime,
      hashType: htlcHashTypeSha3,
      keyMaxSize: htlcPreimageMaxLength,
      hashLock: <int>[4, 5, 6],
    );

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      htlcApi = MockHtlcApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      transactionParams = AccountBlockTemplate(blockType: 1);
      htlc = buildHtlc(timeLocked: selfAddress, expirationTime: now);

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.htlc).thenReturn(htlcApi);
      when(() => htlcApi.getById(htlcId)).thenAnswer((_) async => htlc);
      when(() => htlcApi.reclaim(htlcId)).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'reclaim deposit',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => transactionParams);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = ReclaimDepositBloc(
        accountBlockUtils: accountBlockUtils,
        walletAddresses: <String>{selfAddress.toString()},
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
        unixTimeProvider: () => now,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const ReclaimDepositInitial());
    });

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'submits the reclaim transaction and refreshes balances',
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <ReclaimDepositState>[
        const ReclaimDepositLoading(),
        ReclaimDepositDone(block: transactionParams),
      ],
      verify: (_) {
        verify(() => htlcApi.getById(htlcId)).called(1);
        verify(() => htlcApi.reclaim(htlcId)).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'reclaim deposit',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'rejects a deposit that does not belong to the wallet',
      setUp: () {
        htlc = buildHtlc(timeLocked: otherAddress, expirationTime: now);
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <Matcher>[
        isA<ReclaimDepositLoading>(),
        isA<ReclaimDepositFailure>().having(
          (ReclaimDepositFailure state) => state.exception.message,
          'message',
          'The deposit does not belong to you.',
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'rejects a deposit that is still locked',
      setUp: () {
        htlc = buildHtlc(timeLocked: selfAddress, expirationTime: now + 1);
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () {
        final String expectedDate = FormatUtils.formatDate(
          (now + 1) * Duration.millisecondsPerSecond,
          dateFormat: kDefaultDateTimeFormat,
        );
        return <Matcher>[
          isA<ReclaimDepositLoading>(),
          isA<ReclaimDepositFailure>().having(
            (ReclaimDepositFailure state) => state.exception.message,
            'message',
            'The deposit is locked until $expectedDate.',
          ),
        ];
      },
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'preserves a SyriusException from transaction submission',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'reclaim deposit',
            address: selfAddress,
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(SyriusException('Unable to reclaim deposit.'));
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <Matcher>[
        isA<ReclaimDepositLoading>(),
        isA<ReclaimDepositFailure>().having(
          (ReclaimDepositFailure state) => state.exception.message,
          'message',
          'Unable to reclaim deposit.',
        ),
      ],
      verify: (_) {
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    blocTest<ReclaimDepositBloc, ReclaimDepositState>(
      'converts an unexpected error to FailureException',
      setUp: () {
        when(() => htlcApi.getById(htlcId)).thenThrow(StateError('boom'));
      },
      build: () => bloc,
      act: (ReclaimDepositBloc bloc) =>
          bloc.add(ReclaimDepositRequested(depositId: htlcId)),
      expect: () => <Matcher>[
        isA<ReclaimDepositLoading>(),
        isA<ReclaimDepositFailure>().having(
          (ReclaimDepositFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      verify: (_) {
        verifyNever(() => htlcApi.reclaim(htlcId));
        verifyNever(() => zenonAddressUtils.refreshBalance());
      },
    );

    test(
      'sanitizes unexpected reclaim errors before reporting to BlocObserver',
      () async {
        const String sensitiveDetail = 'sensitive-reclaim-detail';
        final BlocObserver previousObserver = Bloc.observer;
        final _RecordingBlocObserver observer = _RecordingBlocObserver();
        Bloc.observer = observer;
        addTearDown(() => Bloc.observer = previousObserver);

        when(
          () => htlcApi.getById(htlcId),
        ).thenThrow(StateError(sensitiveDetail));

        final ReclaimDepositBloc observedBloc = ReclaimDepositBloc(
          accountBlockUtils: accountBlockUtils,
          walletAddresses: <String>{selfAddress.toString()},
          zenon: zenon,
          zenonAddressUtils: zenonAddressUtils,
          unixTimeProvider: () => now,
        )..add(ReclaimDepositRequested(depositId: htlcId));
        addTearDown(observedBloc.close);

        await expectLater(
          observedBloc.stream,
          emitsThrough(isA<ReclaimDepositFailure>()),
        );

        expect(observer.errors, hasLength(1));
        expect(observer.errors.single, isA<RedactedSwapError>());
        expect(observer.errors.single.toString(), 'StateError');
        expect(
          observer.errors.single.toString(),
          isNot(contains(sensitiveDetail)),
        );
      },
    );
  });
}
