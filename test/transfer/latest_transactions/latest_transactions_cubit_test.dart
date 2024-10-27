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
    const pageKey = 1;
    const pageSize = 10;

    final mockAccountBlock = MockAccountBlock();
    final mockAccountBlockList = MockAccountBlockList();
    final exception = Exception();

    test('initial state is correct', () {
      expect(latestTransactionsCubit.state.status,
          LatestTransactionsStatus.initial,
      );
    });

    blocTest<LatestTransactionsCubit, LatestTransactionsState>(
      'emits [loading, success] with data on successful fetch',
      setUp: () {
        when(() => mockAccountBlockList.list).thenReturn([mockAccountBlock]);
        when(() => mockLedger.getAccountBlocksByPage(
          any(),
          pageIndex: pageKey,
          pageSize: pageSize,
        ),
        ).thenAnswer((_) async => mockAccountBlockList);
      },
      build: () => latestTransactionsCubit,
      act: (cubit) => cubit.getData(pageKey, pageSize),
      expect: () => <LatestTransactionsState>[
        const LatestTransactionsState(status: LatestTransactionsStatus.loading),
        LatestTransactionsState(
          status: LatestTransactionsStatus.success,
          data: [mockAccountBlock],
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
      act: (cubit) => cubit.getData(pageKey, pageSize),
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
