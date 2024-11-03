//ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/receive_transaction/cubit/receive_transaction_cubit.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';


class MockZenon extends Mock implements Zenon {}
class MockAutoReceiveTxWorker extends Mock implements AutoReceiveTxWorker {}
class MockContext extends Mock implements BuildContext {}
class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}
class MockHash extends Fake implements Hash {}

void main() {
  registerFallbackValue(MockHash());

  late MockZenon mockZenon;
  late MockAutoReceiveTxWorker mockAutoReceiveTxWorker;
  late ReceiveTransactionCubit receiveTransactionCubit;
  late MockAccountBlockTemplate response;

  setUp(() {
    mockZenon = MockZenon();
    mockAutoReceiveTxWorker = MockAutoReceiveTxWorker();
    response = MockAccountBlockTemplate();

    receiveTransactionCubit = ReceiveTransactionCubit(
      mockZenon,
      mockAutoReceiveTxWorker,);
  });

  tearDown(() {
    receiveTransactionCubit.close();
  });

  group('ReceiveTransactionCubit', () {
    final Exception exception = Exception();

    test('initial state is correct', () {
      expect(receiveTransactionCubit.state.status,
          ReceiveTransactionStatus.initial,
      );
    });

    blocTest<ReceiveTransactionCubit, ReceiveTransactionState>(
      'emits [loading, success] on successful transaction receipt',
      setUp: () {
        when(() => mockAutoReceiveTxWorker.autoReceiveTransactionHash(any()))
            .thenAnswer((_) async => response);
      },
      build: () => receiveTransactionCubit,
      act: (ReceiveTransactionCubit cubit) => cubit.receiveTransaction(
          emptyHash.toString(),
          MockContext(),
      ),
      expect: () => <ReceiveTransactionState>[
        const ReceiveTransactionState(status: ReceiveTransactionStatus.loading),
        ReceiveTransactionState(
          status: ReceiveTransactionStatus.success,
          data: response,
        ),
      ],
    );

    blocTest<ReceiveTransactionCubit, ReceiveTransactionState>(
      'emits [loading, failure] on transaction receipt failure',
      setUp: () {
        when(() => mockAutoReceiveTxWorker.autoReceiveTransactionHash(any()))
            .thenThrow(exception);
      },
      build: () => receiveTransactionCubit,
      act: (ReceiveTransactionCubit cubit) => cubit.receiveTransaction(
          emptyHash.toString(),
          MockContext(),
      ),
      expect: () => <ReceiveTransactionState>[
        ReceiveTransactionState(status: ReceiveTransactionStatus.loading),
        ReceiveTransactionState(
          status: ReceiveTransactionStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
