import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/failure_exception.dart';
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
    late MockZenon mockZenon;
    late MockLedger mockLedger;
    late LatestTransactionsBloc latestTransactionsBloc;
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
        () => mockLedger.getAccountBlocksByPage(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => accountBlockList);

      latestTransactionsBloc = LatestTransactionsBloc(
        zenon: mockZenon,
      );
    });

    tearDown(() {
      latestTransactionsBloc.close();
    });

    test('initial state is correct', () {
      expect(
        latestTransactionsBloc.state.status,
        LatestTransactionsStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const LatestTransactionsState initialState = LatestTransactionsState();

        final Map<String, dynamic>? serialized = latestTransactionsBloc.toJson(
          initialState,
        );
        final LatestTransactionsState? deserialized =
            latestTransactionsBloc.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize success state', () {
        final LatestTransactionsState successState = LatestTransactionsState(
          status: LatestTransactionsStatus.success,
          data: <AccountBlock>[accountBlock],
        );

        final Map<String, dynamic>? serialized = latestTransactionsBloc.toJson(
          successState,
        );
        final LatestTransactionsState? deserialized =
            latestTransactionsBloc.fromJson(
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

        final Map<String, dynamic>? serialized = latestTransactionsBloc.toJson(
          failureState,
        );
        final LatestTransactionsState? deserialized =
            latestTransactionsBloc.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<LatestTransactionsBloc, LatestTransactionsState>(
      'emits [success] with data is successfully fetched',
      build: () => latestTransactionsBloc,
      act: (LatestTransactionsBloc cubit) => cubit.add(
        LatestTransactionsRequested(
          address: emptyAddress,
        ),
      ),
      expect: () => <LatestTransactionsState>[
        LatestTransactionsState(
          status: LatestTransactionsStatus.success,
          data: <AccountBlock>[accountBlock],
        ),
      ],
    );

    blocTest<LatestTransactionsBloc, LatestTransactionsState>(
      'emits [failure] on fetch failure',
      setUp: () {
        when(
          () => mockLedger.getAccountBlocksByPage(
            any(),
            pageIndex: pageKey,
            pageSize: pageSize,
          ),
        ).thenThrow(exception);
      },
      build: () => latestTransactionsBloc,
      act: (LatestTransactionsBloc cubit) => cubit.add(
        LatestTransactionsRequested(
          address: emptyAddress,
        ),
      ),
      expect: () => <LatestTransactionsState>[
        LatestTransactionsState(
          status: LatestTransactionsStatus.failure,
          error: exception,
        ),
      ],
    );

    blocTest<LatestTransactionsBloc, LatestTransactionsState>(
      'emits [initial, success] when refresh is requested',
      build: () => latestTransactionsBloc,
      act: (LatestTransactionsBloc cubit) => cubit.add(
        LatestTransactionsRefreshRequested(
          address: emptyAddress,
        ),
      ),
      expect: () => <LatestTransactionsState>[
        const LatestTransactionsState(),
        LatestTransactionsState(
          status: LatestTransactionsStatus.success,
          data: <AccountBlock>[accountBlock],
        ),
      ],
    );
  });
}
