import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/latest_transactions/cubit/latest_transactions_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
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

  group('LatestTransactionsCubit', () {
    late MockZenon mockZenon;
    late MockLedger mockLedger;
    late LatestTransactionsCubit latestTransactionsCubit;
    late AccountBlock accountBlock;
    late AccountBlockList accountBlockList;
    late int pageKey;
    late int pageSize;
    late CubitFailureException exception;

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

      exception = CubitFailureException();
      when(() => mockZenon.ledger).thenReturn(mockLedger);
      when(
        () => mockLedger.getAccountBlocksByPage(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => accountBlockList);

      latestTransactionsCubit = LatestTransactionsCubit(
        zenon: mockZenon,
        address: emptyAddress,
      );
    });

    tearDown(() {
      latestTransactionsCubit.close();
    });

    test('initial state is correct', () {
      expect(
        latestTransactionsCubit.state.status,
        LatestTransactionsStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const LatestTransactionsState initialState = LatestTransactionsState();

        final Map<String, dynamic>? serialized = latestTransactionsCubit.toJson(
          initialState,
        );
        final LatestTransactionsState? deserialized =
            latestTransactionsCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const LatestTransactionsState loadingState = LatestTransactionsState(
          status: LatestTransactionsStatus.loading,
        );

        final Map<String, dynamic>? serialized = latestTransactionsCubit.toJson(
          loadingState,
        );
        final LatestTransactionsState? deserialized =
            latestTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final LatestTransactionsState successState = LatestTransactionsState(
          status: LatestTransactionsStatus.success,
          data: <AccountBlock>[accountBlock],
        );

        final Map<String, dynamic>? serialized = latestTransactionsCubit.toJson(
          successState,
        );
        final LatestTransactionsState? deserialized =
            latestTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, isA<LatestTransactionsState>());
        expect(deserialized!.status, equals(LatestTransactionsStatus.success));
        expect(deserialized.data, isA<List<AccountBlock>?>());
      });

      test('can (de)serialize failure state', () {
        final LatestTransactionsState failureState = LatestTransactionsState(
          status: LatestTransactionsStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = latestTransactionsCubit.toJson(
          failureState,
        );
        final LatestTransactionsState? deserialized =
            latestTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<LatestTransactionsCubit, LatestTransactionsState>(
      'emits [loading, success] with data on successful fetch',
      build: () => latestTransactionsCubit,
      act: (LatestTransactionsCubit cubit) => cubit.getData(pageKey, pageSize),
      expect: () => <LatestTransactionsState>[
        const LatestTransactionsState(status: LatestTransactionsStatus.loading),
        LatestTransactionsState(
          status: LatestTransactionsStatus.success,
          data: <AccountBlock>[accountBlock],
        ),
      ],
    );

    // TODO(maznwell): test not working. seems to be an equatable-related problem, but can't figure it out.
    blocTest<LatestTransactionsCubit, LatestTransactionsState>(
      'emits [loading, failure] on fetch failure',
      setUp: () {
        when(
          () => mockLedger.getAccountBlocksByPage(
            any(),
            pageIndex: pageKey,
            pageSize: pageSize,
          ),
        ).thenThrow(exception);
      },
      build: () => latestTransactionsCubit,
      act: (LatestTransactionsCubit cubit) => cubit.getData(pageKey, pageSize),
      expect: () => <LatestTransactionsState>[
        const LatestTransactionsState(status: LatestTransactionsStatus.loading),
        LatestTransactionsState(
          status: LatestTransactionsStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
