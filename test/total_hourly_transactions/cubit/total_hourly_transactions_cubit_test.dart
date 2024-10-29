// ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/rearchitecture.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockLedger extends Mock implements LedgerApi {}

class MockDetailedMomentumList extends Mock implements DetailedMomentumList {}

class MockDetailedMomentum extends Mock implements DetailedMomentum {}

class MockMomentum extends Mock implements Momentum {}

class MockAccountBlock extends Mock implements AccountBlock {}

void main() {
  initHydratedStorage();
  
  group('TotalHourlyTransactionsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockLedger mockLedger;
    late TotalHourlyTransactionsCubit transactionsCubit;
    late SyriusException fetchException;
    late MockMomentum mockMomentum;
    late MockDetailedMomentum mockDetailedMomentum;
    late MockDetailedMomentumList mockDetailedMomentumList;
    late MockAccountBlock mockAccBlock;
    late Map<String, dynamic> transactions;

    setUp(() async {
      mockZenon = MockZenon();
      mockLedger = MockLedger();
      mockWsClient = MockWsClient();
      transactionsCubit = TotalHourlyTransactionsCubit(mockZenon, TotalHourlyTransactionsState());
      fetchException = NotEnoughMomentumsException();
      mockMomentum = MockMomentum();
      mockDetailedMomentum = MockDetailedMomentum();
      mockDetailedMomentumList = MockDetailedMomentumList();
      mockAccBlock = MockAccountBlock();
      transactions = {
        'numAccountBlocks' : 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.ledger).thenReturn(mockLedger);
      when(() => mockLedger.getFrontierMomentum()).thenAnswer((_) async => mockMomentum);
      when(() => mockLedger.getDetailedMomentumsByHeight(any(), any()))
          .thenAnswer((_) async => mockDetailedMomentumList);
      when(() => mockMomentum.height).thenReturn(10000);
    });



    test('initial status is correct', () {
      final cubit = TotalHourlyTransactionsCubit(mockZenon, TotalHourlyTransactionsState());
      expect(cubit.state.status, TimerStatus.initial);
    });

    group('fetch', () {
      blocTest<TotalHourlyTransactionsCubit, TotalHourlyTransactionsState>(
        'calls getFrontierMomentum and getDetailedMomentumsByHeight once',
        build: () => transactionsCubit,
        act: (cubit) => cubit.fetch(),
        verify: (_) {
          verify(() => mockLedger.getFrontierMomentum()).called(1);
          verify(() => mockLedger.getDetailedMomentumsByHeight(10000 - kMomentumsPerHour, kMomentumsPerHour)).called(1);
        },
      );

      //TODO: this test is not done;
      blocTest<TotalHourlyTransactionsCubit, TotalHourlyTransactionsState>(
        'emits [loading, success] when fetch returns',
        setUp: () {
          when(() => mockDetailedMomentumList.list)
              .thenReturn([mockDetailedMomentum]);
          when(() => mockDetailedMomentum.blocks).thenReturn([mockAccBlock]);

        },
        build: () => transactionsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => [
          TotalHourlyTransactionsState(status: TimerStatus.loading),
          TotalHourlyTransactionsState(
            status: TimerStatus.success,
          ),
        ],
      );

      blocTest<TotalHourlyTransactionsCubit, TotalHourlyTransactionsState>(
        'emits [loading, failure] when fetch throws an error',
        setUp: () {
          when(() => mockLedger.getFrontierMomentum()).thenThrow(fetchException);
        },
        build: () => transactionsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <TotalHourlyTransactionsState>[
          TotalHourlyTransactionsState(status: TimerStatus.loading),
          TotalHourlyTransactionsState(
            status: TimerStatus.failure,
            error: fetchException,
          ),
        ],
      );
    });
  });
}
