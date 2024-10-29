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


void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('BalanceCubit', () {
    late MockZenon mockZenon;
    late MockLedger mockLedger;
    late MockWsClient mockWsClient;
    late BalanceCubit balanceCubit;
    late AccountInfo accountInfo;
    late BalanceInfoListItem balanceInfoListItem;
    late SyriusException balanceException;

    setUp(() async {
      mockZenon = MockZenon();
      mockLedger = MockLedger();
      mockWsClient = MockWsClient();

      balanceInfoListItem = BalanceInfoListItem(
          token: kZnnCoin,
          balance: BigInt.from(5),
      );

      accountInfo = AccountInfo(
          address: emptyAddress.toString(),
          blockCount: 1,
          balanceInfoList: [balanceInfoListItem],
      );

      balanceCubit = BalanceCubit(emptyAddress, mockZenon, BalanceState());
      balanceException = NoBalanceException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.ledger).thenReturn(mockLedger);

      when(() => mockLedger.getAccountInfoByAddress(any()),
      ).thenAnswer((_) async => accountInfo);

    });

    test('initial status is correct', () {
      final balanceCubit = BalanceCubit(
        emptyAddress,
        mockZenon,
        BalanceState(),
      );
      expect(balanceCubit.state.status, TimerStatus.initial);
    });

    group('fetchDataPeriodically', () {
      blocTest<BalanceCubit, TimerState>(
        'calls getAccountInfoByAddress once',
        build: () => balanceCubit,
        setUp: () {
          when(() => mockLedger.getAccountInfoByAddress(any()),
          ).thenAnswer((_) async => accountInfo);
        },
        act: (cubit) => cubit.fetch(),
        verify: (_) {
            verify(() =>
                mockLedger.getAccountInfoByAddress(any()),
            ).called(1);
        },
      );

      blocTest<BalanceCubit, TimerState>(
        'emits [loading, failure] when fetch throws',
        build: () => balanceCubit,
        setUp: () {
          when(() => mockLedger.getAccountInfoByAddress(any()),
          ).thenThrow(balanceException);
        },
        act: (cubit) => cubit.fetchDataPeriodically(),
          expect: () => <BalanceState>[
            BalanceState(status: TimerStatus.loading),
            BalanceState(
              status: TimerStatus.failure,
              error: balanceException,
            ),
        ],
      );

      blocTest<BalanceCubit, TimerState>(
        'emits [loading, success] when fetch returns',
        build: () => balanceCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
          expect: () => <BalanceState>[
            BalanceState(status: TimerStatus.loading),
            BalanceState(status: TimerStatus.success,
            data: accountInfo,
            ),
          ],
      );
    });
  });
}
