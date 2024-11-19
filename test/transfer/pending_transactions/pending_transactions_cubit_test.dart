import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/pending_transactions/cubit/pending_transactions_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/failure_exception.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockLedger extends Mock implements LedgerApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('PendingTransactionsCubit', () {
    late MockZenon mockZenon;
    late MockLedger mockLedger;
    late PendingTransactionsCubit pendingTransactionsCubit;
    late AccountBlock accountBlock;
    late AccountBlockList accountBlockList;
    late int pageKey;
    late int pageSize;
    late FailureException exception;

    setUp(() async {
      final Map<String, dynamic> confirmationDetailJson = <String, dynamic>{
        'numConfirmations': 42,
        'momentumHeight': 12345,
        'momentumHash': emptyHash.toString(),
        'momentumTimestamp': 1625132800,
      };

      final Map<String, dynamic> accountBlockJson = <String, dynamic>{
        'descendantBlocks': <AccountBlock>[],
        'basePlasma': 1000,
        'usedPlasma': 500,
        'changesHash': emptyHash.toString(),
        'confirmationDetail': confirmationDetailJson,
        'version': 1,
        'chainIdentifier': 1,
        'blockType': 2,
        'hash': emptyHash.toString(),
        'previousHash': emptyHash.toString(),
        'height': 100,
        'momentumAcknowledged': <String, dynamic>{
          'hash': emptyHash.toString(),
          'height': 99,
        },
        'address': emptyAddress.toString(),
        'toAddress': emptyAddress.toString(),
        'amount': '1000000000',
        'tokenStandard': znnTokenStandard,
        'fromBlockHash': emptyHash.toString(),
        'data': null,
        'fusedPlasma': 0,
        'difficulty': 0,
        'nonce': '1',
        'publicKey': null,
        'signature': null,
        'token': kZnnCoin.toJson(),
        'pairedAccountBlock': null,
      };

      mockZenon = MockZenon();
      mockLedger = MockLedger();
      pageKey = 1;
      pageSize = 10;
      accountBlock = AccountBlock.fromJson(accountBlockJson);
      accountBlockList = AccountBlockList(
        count: 1,
        list: <AccountBlock>[accountBlock],
        more: false,
      );

      exception = FailureException();
      when(() => mockZenon.ledger).thenReturn(mockLedger);
      when(
        () => mockLedger.getUnreceivedBlocksByAddress(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => accountBlockList);

      pendingTransactionsCubit = PendingTransactionsCubit(
        zenon: mockZenon,
        address: emptyAddress,
      );
    });

    tearDown(() {
      pendingTransactionsCubit.close();
    });

    test('initial state is correct', () {
      expect(
        pendingTransactionsCubit.state.status,
        PendingTransactionsStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const PendingTransactionsState initialState =
            PendingTransactionsState();

        final Map<String, dynamic>? serialized =
            pendingTransactionsCubit.toJson(
          initialState,
        );
        final PendingTransactionsState? deserialized =
            pendingTransactionsCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const PendingTransactionsState loadingState = PendingTransactionsState(
          status: PendingTransactionsStatus.loading,
        );

        final Map<String, dynamic>? serialized =
            pendingTransactionsCubit.toJson(
          loadingState,
        );
        final PendingTransactionsState? deserialized =
            pendingTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final PendingTransactionsState successState = PendingTransactionsState(
          status: PendingTransactionsStatus.success,
          data: <AccountBlock>[accountBlock],
        );

        final Map<String, dynamic>? serialized =
            pendingTransactionsCubit.toJson(
          successState,
        );
        final PendingTransactionsState? deserialized =
            pendingTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, isA<PendingTransactionsState>());
        expect(deserialized!.status, equals(PendingTransactionsStatus.success));
        expect(deserialized.data, isA<List<AccountBlock>?>());
      });

      test('can (de)serialize failure state', () {
        final PendingTransactionsState failureState = PendingTransactionsState(
          status: PendingTransactionsStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized =
            pendingTransactionsCubit.toJson(
          failureState,
        );
        final PendingTransactionsState? deserialized =
            pendingTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<PendingTransactionsCubit, PendingTransactionsState>(
      'emits [loading, success] with data on successful fetch',
      build: () => pendingTransactionsCubit,
      act: (PendingTransactionsCubit cubit) => cubit.getData(pageKey, pageSize),
      expect: () => <PendingTransactionsState>[
        const PendingTransactionsState(
          status: PendingTransactionsStatus.loading,
        ),
        PendingTransactionsState(
          status: PendingTransactionsStatus.success,
          data: <AccountBlock>[accountBlock],
        ),
      ],
    );

    blocTest<PendingTransactionsCubit, PendingTransactionsState>(
      'emits [loading, failure] on fetch failure',
      setUp: () {
        when(
          () => mockLedger.getUnreceivedBlocksByAddress(
            any(),
            pageIndex: pageKey,
            pageSize: pageSize,
          ),
        ).thenThrow(exception);
      },
      build: () => pendingTransactionsCubit,
      act: (PendingTransactionsCubit cubit) => cubit.getData(pageKey, pageSize),
      expect: () => <PendingTransactionsState>[
        const PendingTransactionsState(
          status: PendingTransactionsStatus.loading,
        ),
        PendingTransactionsState(
          status: PendingTransactionsStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
