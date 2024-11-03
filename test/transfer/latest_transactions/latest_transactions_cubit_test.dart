//ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/latest_transactions/cubit/latest_transactions_cubit.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}
class MockLedger extends Mock implements LedgerApi {}
class MockAccountBlockList extends Mock implements AccountBlockList {}
class MockAccountBlock extends Mock implements AccountBlock {}
class FakeAddress extends Fake implements Address {}

void main() {
  registerFallbackValue(FakeAddress());

  late MockZenon mockZenon;
  late MockLedger mockLedger;
  late LatestTransactionsCubit latestTransactionsCubit;

  setUp(() {
    mockZenon = MockZenon();
    mockLedger = MockLedger();

    when(() => mockZenon.ledger).thenReturn(mockLedger);

    latestTransactionsCubit = LatestTransactionsCubit(mockZenon);
  });

  tearDown(() {
    latestTransactionsCubit.close();
  });

  group('LatestTransactionsCubit', () {
    const int pageKey = 1;
    const int pageSize = 10;

    final MockAccountBlock mockAccountBlock = MockAccountBlock();
    final MockAccountBlockList mockAccountBlockList = MockAccountBlockList();
    final Exception exception = Exception();

    test('initial state is correct', () {
      expect(latestTransactionsCubit.state.status,
          LatestTransactionsStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        final LatestTransactionsState initialState = LatestTransactionsState();

        final Map<String, dynamic>? serialized = latestTransactionsCubit.toJson(
          initialState,
        );
        final LatestTransactionsState? deserialized = latestTransactionsCubit.
        fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        final LatestTransactionsState loadingState = LatestTransactionsState(
          status: LatestTransactionsStatus.loading,
        );

        final Map<String, dynamic>? serialized = latestTransactionsCubit.toJson(
          loadingState,
        );
        final LatestTransactionsState? deserialized = latestTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final LatestTransactionsState successState = LatestTransactionsState(
          status: LatestTransactionsStatus.success,
          data: delegationInfo,
        );

        final Map<String, dynamic>? serialized = latestTransactionsCubit.toJson(
          successState,
        );
        final LatestTransactionsState? deserialized = latestTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final LatestTransactionsState failureState = LatestTransactionsState(
          status: LatestTransactionsStatus.failure,
          error: delegationException,
        );

        final Map<String, dynamic>? serialized = latestTransactionsCubit.toJson(
          failureState,
        );
        final LatestTransactionsState? deserialized = latestTransactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<LatestTransactionsCubit, LatestTransactionsState>(
      'emits [loading, success] with data on successful fetch',
      setUp: () {
        when(() => mockAccountBlockList.list)
            .thenReturn(<AccountBlock>[mockAccountBlock]);
        when(() => mockLedger.getAccountBlocksByPage(
          any(),
          pageIndex: pageKey,
          pageSize: pageSize,
        ),
        ).thenAnswer((_) async => mockAccountBlockList);
      },
      build: () => latestTransactionsCubit,
      act: (LatestTransactionsCubit cubit) => cubit.getData(pageKey, pageSize),
      expect: () => <LatestTransactionsState>[
        const LatestTransactionsState(status: LatestTransactionsStatus.loading),
        LatestTransactionsState(
          status: LatestTransactionsStatus.success,
          data: <AccountBlock>[mockAccountBlock],
        ),
      ],
    );

    blocTest<LatestTransactionsCubit, LatestTransactionsState>(
      'emits [loading, failure] on fetch failure',
      setUp: () {
        when(() => mockLedger.getAccountBlocksByPage(
          any(),
          pageIndex: pageKey,
          pageSize: pageSize,
        ),).thenThrow(exception);
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
