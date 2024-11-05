import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/receive_transaction/cubit/receive_transaction_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockAutoReceiveTxWorker extends Mock implements AutoReceiveTxWorker {}

class MockContext extends Mock implements BuildContext {}

class MockHash extends Fake implements Hash {}

void main() {
  initHydratedStorage();

  registerFallbackValue(MockHash());

  group('ReceiveTransactionCubit', () {
    late MockAutoReceiveTxWorker mockAutoReceiveTxWorker;
    late ReceiveTransactionCubit receiveTransactionCubit;
    late AccountBlockTemplate testAccBlockTemplate;
    late CubitFailureException exception;

    setUp(() {
      mockAutoReceiveTxWorker = MockAutoReceiveTxWorker();
      testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
      exception = CubitFailureException();

      receiveTransactionCubit = ReceiveTransactionCubit(
        mockAutoReceiveTxWorker,
      );

      when(() => mockAutoReceiveTxWorker.autoReceiveTransactionHash(any()))
          .thenAnswer((_) async => testAccBlockTemplate);
    });

    tearDown(() {
      receiveTransactionCubit.close();
    });

    test('initial state is correct', () {
      expect(
        receiveTransactionCubit.state.status,
        ReceiveTransactionStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const ReceiveTransactionState initialState = ReceiveTransactionState();

        final Map<String, dynamic>? serialized = receiveTransactionCubit.toJson(
          initialState,
        );
        final ReceiveTransactionState? deserialized =
            receiveTransactionCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const ReceiveTransactionState loadingState = ReceiveTransactionState(
          status: ReceiveTransactionStatus.loading,
        );

        final Map<String, dynamic>? serialized = receiveTransactionCubit.toJson(
          loadingState,
        );
        final ReceiveTransactionState? deserialized =
            receiveTransactionCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final ReceiveTransactionState successState = ReceiveTransactionState(
          status: ReceiveTransactionStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic>? serialized = receiveTransactionCubit.toJson(
          successState,
        );
        final ReceiveTransactionState? deserialized =
            receiveTransactionCubit.fromJson(
          serialized!,
        );
        expect(deserialized, isA<ReceiveTransactionState>());
        expect(deserialized!.status, equals(ReceiveTransactionStatus.success));
        expect(deserialized.data, isA<AccountBlockTemplate?>());
      });

      test('can (de)serialize failure state', () {
        final ReceiveTransactionState failureState = ReceiveTransactionState(
          status: ReceiveTransactionStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = receiveTransactionCubit.toJson(
          failureState,
        );
        final ReceiveTransactionState? deserialized =
            receiveTransactionCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<ReceiveTransactionCubit, ReceiveTransactionState>(
      'emits [loading, success] on successful transaction receipt',
      build: () => receiveTransactionCubit,
      act: (ReceiveTransactionCubit cubit) => cubit.receiveTransaction(
        emptyHash.toString(),
        MockContext(),
      ),
      expect: () => <ReceiveTransactionState>[
        const ReceiveTransactionState(status: ReceiveTransactionStatus.loading),
        ReceiveTransactionState(
          status: ReceiveTransactionStatus.success,
          data: testAccBlockTemplate,
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
        const ReceiveTransactionState(status: ReceiveTransactionStatus.loading),
        ReceiveTransactionState(
          status: ReceiveTransactionStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
