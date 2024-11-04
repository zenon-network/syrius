//ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/receive_transaction/cubit/receive_transaction_cubit.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockAutoReceiveTxWorker extends Mock implements AutoReceiveTxWorker {}

class MockContext extends Mock implements BuildContext {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

class MockHash extends Fake implements Hash {}

void main() {
  initHydratedStorage();

  registerFallbackValue(MockHash());

  group('ReceiveTransactionCubit', () {
    late MockAutoReceiveTxWorker mockAutoReceiveTxWorker;
    late ReceiveTransactionCubit receiveTransactionCubit;
    late MockAccountBlockTemplate mockAccBlockTemplate;
    late AccountBlockTemplate testAccBlockTemplate;
    late Exception exception;

    setUp(() {
      mockAutoReceiveTxWorker = MockAutoReceiveTxWorker();
      mockAccBlockTemplate = MockAccountBlockTemplate();
      testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
      exception = Exception();

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
        final ReceiveTransactionState initialState = ReceiveTransactionState();

        final Map<String, dynamic>? serialized = receiveTransactionCubit.toJson(
          initialState,
        );
        final ReceiveTransactionState? deserialized =
            receiveTransactionCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        final ReceiveTransactionState loadingState = ReceiveTransactionState(
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
      setUp: () {
        when(() => mockAutoReceiveTxWorker.autoReceiveTransactionHash(any()))
            .thenAnswer((_) async => mockAccBlockTemplate);
      },
      build: () => receiveTransactionCubit,
      act: (ReceiveTransactionCubit cubit) => cubit.receiveTransaction(
        emptyHash.toString(),
        MockContext(),
      ),
      expect: () => <ReceiveTransactionState>[
        ReceiveTransactionState(status: ReceiveTransactionStatus.loading),
        ReceiveTransactionState(
          status: ReceiveTransactionStatus.success,
          data: mockAccBlockTemplate,
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
