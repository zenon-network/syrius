import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/pending_transactions/cubit/pending_transactions_cubit.dart';
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
  late PendingTransactionsCubit pendingTransactionsCubit;

  setUp(() {
    mockZenon = MockZenon();
    mockLedger = MockLedger();

    when(() => mockZenon.ledger).thenReturn(mockLedger);

    pendingTransactionsCubit = PendingTransactionsCubit(mockZenon);
  });

  tearDown(() {
    pendingTransactionsCubit.close();
  });

  group('LatestTransactionsCubit', () {
    const pageKey = 1;
    const pageSize = 10;

    final mockAccountBlock = MockAccountBlock();
    final mockAccountBlockList = MockAccountBlockList();
    final exception = Exception();

    test('initial state is correct', () {
      expect(pendingTransactionsCubit.state.status,
        PendingTransactionsStatus.initial,
      );
    });

    blocTest<PendingTransactionsCubit, PendingTransactionsState>(
      'emits [loading, success] with data on successful fetch',
      setUp: () {
        when(() => mockAccountBlockList.list).thenReturn([mockAccountBlock]);
        when(() => mockLedger.getUnreceivedBlocksByAddress(
          any(),
          pageIndex: pageKey,
          pageSize: pageSize,
        ),
        ).thenAnswer((_) async => mockAccountBlockList);
      },
      build: () => pendingTransactionsCubit,
      act: (cubit) => cubit.getData(pageKey, pageSize),
      expect: () => <PendingTransactionsState>[
        const PendingTransactionsState(
            status: PendingTransactionsStatus.loading,
        ),
        PendingTransactionsState(
          status: PendingTransactionsStatus.success,
          data: [mockAccountBlock],
        ),
      ],
    );

    blocTest<PendingTransactionsCubit, PendingTransactionsState>(
      'emits [loading, failure] on fetch failure',
      setUp: () {
        when(() => mockLedger.getUnreceivedBlocksByAddress(
          any(),
          pageIndex: pageKey,
          pageSize: pageSize,
        ),
        ).thenThrow(exception);
      },
      build: () => pendingTransactionsCubit,
      act: (cubit) => cubit.getData(pageKey, pageSize),
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
