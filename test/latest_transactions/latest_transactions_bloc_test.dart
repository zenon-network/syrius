import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockLedger extends Mock implements LedgerApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('LatestTransactionsBloc', () {
    const int kTestPageSize = 1;
    late MockZenon mockZenon;
    late MockLedger mockLedger;
    late LatestTransactionsBloc latestTransactionsBloc;
    late AccountBlock accountBlock;
    late AccountBlockList accountBlockList;
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
      accountBlock = AccountBlock.fromJson(accountBlockJson);
      accountBlockList = AccountBlockList(
        count: kTestPageSize,
        list: <AccountBlock>[accountBlock],
        more: false,
      );

      exception = FailureException();
      when(() => mockZenon.ledger).thenReturn(mockLedger);
      when(
        () => mockLedger.getAccountBlocksByPage(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => accountBlockList);

      latestTransactionsBloc = LatestTransactionsBloc(
        pageSize: 1,
        zenon: mockZenon,
      );
    });

    tearDown(() {
      latestTransactionsBloc.close();
    });

    test('initial state is correct', () {
      expect(
        latestTransactionsBloc.state.status,
        InfiniteListStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const InfiniteListState<AccountBlock> initialState =
            InfiniteListState<AccountBlock>.initial();

        final Map<String, dynamic>? serialized = latestTransactionsBloc.toJson(
          initialState,
        );
        final InfiniteListState<AccountBlock>? deserialized =
            latestTransactionsBloc.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize success state', () {
        final InfiniteListState<AccountBlock> successState =
            InfiniteListState<AccountBlock>(
          status: InfiniteListStatus.success,
          data: <AccountBlock>[accountBlock],
        );

        final Map<String, dynamic>? serialized = latestTransactionsBloc.toJson(
          successState,
        );
        final InfiniteListState<AccountBlock>? deserialized =
            latestTransactionsBloc.fromJson(
          serialized!,
        );
        expect(deserialized, isA<InfiniteListState<AccountBlock>>());
        expect(deserialized!.status, equals(InfiniteListStatus.success));
        expect(deserialized.data, isA<List<AccountBlock>?>());
      });

      test('can (de)serialize failure state', () {
        final InfiniteListState<AccountBlock> failureState =
            InfiniteListState<AccountBlock>(
          status: InfiniteListStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = latestTransactionsBloc.toJson(
          failureState,
        );
        final InfiniteListState<AccountBlock>? deserialized =
            latestTransactionsBloc.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<LatestTransactionsBloc, InfiniteListState<AccountBlock>>(
      'emits [success] with data is successfully fetched',
      build: () => latestTransactionsBloc,
      act: (LatestTransactionsBloc cubit) => cubit.add(
        InfiniteListRequested(
          address: emptyAddress,
        ),
      ),
      expect: () {
        final List<AccountBlock> data = <AccountBlock>[accountBlock];

        final bool hasReachedMax = data.length < kTestPageSize;

        return <InfiniteListState<AccountBlock>>[
          InfiniteListState<AccountBlock>(
            status: InfiniteListStatus.success,
            data: data,
            hasReachedMax: hasReachedMax,
          ),
        ];
      },
    );

    blocTest<LatestTransactionsBloc, InfiniteListState<AccountBlock>>(
      'emits [failure] on fetch failure',
      setUp: () {
        when(
          () => mockLedger.getAccountBlocksByPage(
            any(),
            pageSize: kTestPageSize,
          ),
        ).thenThrow(exception);
      },
      build: () => latestTransactionsBloc,
      act: (LatestTransactionsBloc cubit) => cubit.add(
        InfiniteListRequested(
          address: emptyAddress,
        ),
      ),
      expect: () => <InfiniteListState<AccountBlock>>[
        InfiniteListState<AccountBlock>(
          status: InfiniteListStatus.failure,
          error: exception,
        ),
      ],
    );

    blocTest<LatestTransactionsBloc, InfiniteListState<AccountBlock>>(
      'emits [initial, success] when refresh is requested',
      build: () => latestTransactionsBloc,
      act: (LatestTransactionsBloc cubit) => cubit.add(
        InfiniteListRefreshRequested(
          address: emptyAddress,
        ),
      ),
      expect: () {
        final List<AccountBlock> data = <AccountBlock>[accountBlock];

        final bool hasReachedMax = data.length < kTestPageSize;

        return <InfiniteListState<AccountBlock>>[
          const InfiniteListState<AccountBlock>.initial(),
          InfiniteListState<AccountBlock>(
            status: InfiniteListStatus.success,
            data: data,
            hasReachedMax: hasReachedMax,
          ),
        ];
      },
    );

    blocTest<LatestTransactionsBloc, InfiniteListState<AccountBlock>>(
      'emits [initial, success, success] when more transactions are requested',
      build: () => latestTransactionsBloc,
      act: (LatestTransactionsBloc bloc) async {
        bloc.add(
          InfiniteListRefreshRequested(
            address: emptyAddress,
          ),
        );

        // New events sent immediately one after the other will be dropped
        await Future<void>.delayed(const Duration(milliseconds: 200));

        bloc.add(
          InfiniteListMoreRequested(
            address: emptyAddress,
          ),
        );
      },
      expect: () {
        final List<AccountBlock> data = <AccountBlock>[accountBlock];

        final bool hasReachedMax = data.length < kTestPageSize;

        return <InfiniteListState<AccountBlock>>[
          const InfiniteListState<AccountBlock>.initial(),
          InfiniteListState<AccountBlock>(
            status: InfiniteListStatus.success,
            data: data,
            hasReachedMax: hasReachedMax,
          ),
          InfiniteListState<AccountBlock>(
            status: InfiniteListStatus.success,
            data: <AccountBlock>[
              ...data,
              ...data,
            ],
            hasReachedMax: hasReachedMax,
          ),
        ];
      },
    );
  });
}