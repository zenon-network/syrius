// ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/rearchitecture.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';


import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockLedger extends Mock implements LedgerApi {}

class FakeAddress extends Fake implements Address {}

class MockAccountBlock extends Mock implements AccountBlock {}

class MockMomentum extends Mock implements Momentum {}

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
    late MockMomentum mockMomentum;
    late AccountBlock accountBlock;

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

      accountBlock = AccountBlock.fromJson(accountBlockJson);

      final AccountBlockList accountBlockList = AccountBlockList(
          count: 1,
          list: <AccountBlock>[accountBlock],
          more: false,
      );


      mockZenon = MockZenon();
      mockLedger = MockLedger();
      mockWsClient = MockWsClient();
      statsCubit = RealtimeStatisticsCubit(
          address: emptyAddress,
          zenon: mockZenon,
      );
      statsException = NoBlocksAvailableException();
      mockMomentum = MockMomentum();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.ledger).thenReturn(mockLedger);
      when(() => mockLedger.getFrontierMomentum())
          .thenAnswer((_) async => mockMomentum);
      when(() => mockMomentum.height)
          .thenReturn(kMomentumsPerWeek + 100);
      when(() => mockLedger.getAccountBlocksByPage(any(),
        pageIndex: any(named: 'pageIndex'),
        pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => accountBlockList);
    });

    test('initial status is correct', () {
      expect(statsCubit.state.status, TimerStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        final RealtimeStatisticsState initialState = RealtimeStatisticsState();

        final Map<String, dynamic>? serialized = statsCubit.toJson(
          initialState,
        );
        final RealtimeStatisticsState? deserialized = statsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        final RealtimeStatisticsState loadingState = RealtimeStatisticsState(
          status: TimerStatus.loading,
        );

        final Map<String, dynamic>? serialized = statsCubit.toJson(
          loadingState,
        );
        final RealtimeStatisticsState? deserialized = statsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final RealtimeStatisticsState successState = RealtimeStatisticsState(
          status: TimerStatus.success,
          data: <AccountBlock>[accountBlock],
        );

        final Map<String, dynamic>? serialized = statsCubit.toJson(
          successState,
        );
        final RealtimeStatisticsState? deserialized = statsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final RealtimeStatisticsState failureState = RealtimeStatisticsState(
          status: TimerStatus.failure,
          error: statsException,
        );

        final Map<String, dynamic>? serialized = statsCubit.toJson(
          failureState,
        );
        final RealtimeStatisticsState? deserialized = statsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    group('fetch', () {
      blocTest<RealtimeStatisticsCubit, RealtimeStatisticsState>(
        'calls getFrontierMomentum and getAccountBlocksByPage once',
        build: () => statsCubit,
        act: (RealtimeStatisticsCubit cubit) => cubit.fetch(),
        verify: (_) {
          verify(() => mockLedger.getFrontierMomentum()).called(1);
          verify(() => mockLedger.getAccountBlocksByPage(
              any(),
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
            ),
          ).called(1);
        },
      );

      // TODO(maznwell): fix equality between AccountBlock instances
      blocTest<RealtimeStatisticsCubit, RealtimeStatisticsState>(
        'emits [loading, success] when fetch returns',
        build: () => statsCubit,
        act: (RealtimeStatisticsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <RealtimeStatisticsState>[
          RealtimeStatisticsState(status: TimerStatus.loading),
          RealtimeStatisticsState(
            status: TimerStatus.success,
            data: <AccountBlock>[accountBlock],
          ),
        ],
      );

      blocTest<RealtimeStatisticsCubit, RealtimeStatisticsState>(
        'emits [loading, failure] when fetch throws an error',
        setUp: () {
          when(() => mockLedger.getFrontierMomentum())
              .thenThrow(statsException);
        },
        build: () => statsCubit,
        act: (RealtimeStatisticsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <RealtimeStatisticsState>[
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
