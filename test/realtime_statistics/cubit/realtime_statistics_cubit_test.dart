// ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/rearchitecture.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';


import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockLedger extends Mock implements LedgerApi {}

class FakeAddress extends Fake implements Address {}

class MockAccountBlock extends Mock implements AccountBlock {}

class FakeMomentum extends Fake implements Momentum {
  @override
  int get height => 100;
}

class MockAccountBlockList extends Mock implements AccountBlockList {}


void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('RealtimeStatisticsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockLedger mockLedger;
    late RealtimeStatisticsCubit statsCubit;
    late SyriusException statsException;
    late List<AccountBlock> listAccBlock;
    late FakeMomentum fakeMomentum;
    late AccountBlockList accBlockList;

    setUp(() async {
      mockZenon = MockZenon();
      mockLedger = MockLedger();
      mockWsClient = MockWsClient();
      statsCubit = RealtimeStatisticsCubit(mockZenon, RealtimeStatisticsState());
      statsException = NoBlocksAvailableException();
      listAccBlock = [MockAccountBlock()];
      fakeMomentum = FakeMomentum();
      accBlockList = AccountBlockList(count: 1, list: listAccBlock, more: false);
      kSelectedAddress = 'z1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsggv2f';


      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.ledger).thenReturn(mockLedger);
    });

    test('initial status is correct', () {
      final cubit = RealtimeStatisticsCubit(mockZenon, RealtimeStatisticsState());
      expect(cubit.state.status, TimerStatus.initial);
    });

    //TODO: test not finished;
    group('fetch', () {
      blocTest<RealtimeStatisticsCubit, RealtimeStatisticsState>(
        'calls getFrontierMomentum and getAccountBlocksByPage once',
        setUp: () {
          when(() => mockLedger.getFrontierMomentum()).thenAnswer((_) async => fakeMomentum);

          when(() => mockLedger.getAccountBlocksByPage(any())).thenAnswer((_) async => accBlockList);
          // when(() => accBlockList.list).thenReturn(listAccBlock);
        },
        build: () => statsCubit,
        act: (cubit) => cubit.fetch(),
        verify: (_) {
          verify(() => mockLedger.getFrontierMomentum()).called(1);
          verify(() => mockLedger.getAccountBlocksByPage(any())).called(1);
        },
      );

      //TODO: test not finished;
      blocTest<RealtimeStatisticsCubit, RealtimeStatisticsState>(
        'emits [loading, success] when fetch returns',
        setUp: () {
          when(() => statsCubit.fetch()).thenAnswer((_) async => listAccBlock);
        },
        build: () => statsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => [
          RealtimeStatisticsState(status: TimerStatus.loading),
          RealtimeStatisticsState(
            status: TimerStatus.success,
            data: listAccBlock,
          ),
        ],
      );

      blocTest<RealtimeStatisticsCubit, TimerState>(
        'emits [loading, failure] when fetch throws an error',
        setUp: () {
          when(() => mockLedger.getFrontierMomentum()).thenThrow(statsException);
        },
        build: () => statsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => [
          RealtimeStatisticsState(status: TimerStatus.loading),
          RealtimeStatisticsState(
            status: TimerStatus.failure,
            error: statsException,
          ),
        ],
      );
    });
  });
}
