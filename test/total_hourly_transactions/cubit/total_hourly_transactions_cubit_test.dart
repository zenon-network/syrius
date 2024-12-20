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

    setUp(() async {
      mockZenon = MockZenon();
      mockLedger = MockLedger();
      mockWsClient = MockWsClient();
      transactionsCubit = TotalHourlyTransactionsCubit(
          zenon: mockZenon,
      );
      fetchException = NotEnoughMomentumsException();
      mockMomentum = MockMomentum();
      mockDetailedMomentum = MockDetailedMomentum();
      mockDetailedMomentumList = MockDetailedMomentumList();
      mockAccBlock = MockAccountBlock();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.ledger).thenReturn(mockLedger);

      when(() => mockLedger.getFrontierMomentum())
          .thenAnswer((_) async => mockMomentum);
      when(() => mockMomentum.height)
          .thenReturn(kMomentumsPerHour + 1);
      when(() => mockLedger.getDetailedMomentumsByHeight(any(), any()))
          .thenAnswer((_) async => mockDetailedMomentumList);
      when(() => mockDetailedMomentumList.list)
          .thenReturn(<DetailedMomentum>[mockDetailedMomentum]);
      when(() => mockDetailedMomentum.blocks)
          .thenReturn(<AccountBlock>[mockAccBlock, mockAccBlock]);
    });

    test('initial status is correct', () {
      final TotalHourlyTransactionsCubit cubit = TotalHourlyTransactionsCubit(
         zenon: mockZenon,
      );
      expect(cubit.state.status, TimerStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const TotalHourlyTransactionsState initialState =
        TotalHourlyTransactionsState();

        final Map<String, dynamic>? serialized = transactionsCubit.toJson(
          initialState,
        );
        final TotalHourlyTransactionsState? deserialized =
        transactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const TotalHourlyTransactionsState loadingState =
        TotalHourlyTransactionsState(
          status: TimerStatus.loading,
        );

        final Map<String, dynamic>? serialized = transactionsCubit.toJson(
          loadingState,
        );
        final TotalHourlyTransactionsState? deserialized =
        transactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        const TotalHourlyTransactionsState successState =
        TotalHourlyTransactionsState(
          status: TimerStatus.success,
          data: 2,
        );

        final Map<String, dynamic>? serialized = transactionsCubit.toJson(
          successState,
        );
        final TotalHourlyTransactionsState? deserialized =
        transactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final TotalHourlyTransactionsState failureState =
        TotalHourlyTransactionsState(
          status: TimerStatus.failure,
          error: fetchException,
        );

        final Map<String, dynamic>? serialized = transactionsCubit.toJson(
          failureState,
        );
        final TotalHourlyTransactionsState? deserialized =
        transactionsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    group('fetch', () {
      blocTest<TotalHourlyTransactionsCubit, TotalHourlyTransactionsState>(
        'calls getFrontierMomentum and getDetailedMomentumsByHeight once',
        build: () => transactionsCubit,
        act: (TotalHourlyTransactionsCubit cubit) => cubit.fetch(),
        verify: (_) {
          verify(() => mockLedger.getFrontierMomentum()).called(1);
          verify(() => mockLedger.getDetailedMomentumsByHeight(any(), any()))
              .called(1);
        },
      );

      blocTest<TotalHourlyTransactionsCubit, TotalHourlyTransactionsState>(
        'emits [loading, success] when fetch returns',
        build: () => transactionsCubit,
        act: (TotalHourlyTransactionsCubit cubit)
                                        => cubit.fetchDataPeriodically(),
        expect: () => <TotalHourlyTransactionsState>[
          const TotalHourlyTransactionsState(status: TimerStatus.loading),
          const TotalHourlyTransactionsState(
            status: TimerStatus.success,
            data: 2,
          ),
        ],
      );

      blocTest<TotalHourlyTransactionsCubit, TotalHourlyTransactionsState>(
        'emits [loading, failure] when fetch throws an error',
        setUp: () {
          when(() => mockLedger.getFrontierMomentum())
              .thenThrow(fetchException);
        },
        build: () => transactionsCubit,
        act: (TotalHourlyTransactionsCubit cubit)
                                            => cubit.fetchDataPeriodically(),
        expect: () => <TotalHourlyTransactionsState>[
          const TotalHourlyTransactionsState(status: TimerStatus.loading),
          TotalHourlyTransactionsState(
            status: TimerStatus.failure,
            error: fetchException,
          ),
        ],
      );
    });
  });
}
