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
    late CubitException balanceException;

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
          balanceInfoList: <BalanceInfoListItem>[balanceInfoListItem],
      );

      balanceCubit = BalanceCubit(
          address: emptyAddress,
          zenon: mockZenon,
      );
      balanceException = NoBalanceException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.ledger).thenReturn(mockLedger);

      when(() => mockLedger.getAccountInfoByAddress(any()),
      ).thenAnswer((_) async => accountInfo);

    });

    test('initial status is correct', () {
      final BalanceCubit balanceCubit = BalanceCubit(
        address: emptyAddress,
        zenon: mockZenon,
      );
      expect(balanceCubit.state.status, TimerStatus.initial);
    });

    //TODO: problem:fromJson List - Map
    test('can be (de)serialized', () {
      final BalanceState balanceState = BalanceState(
        data: accountInfo,
        status: TimerStatus.success,
      );

      final Map<String, dynamic>? serialized = balanceCubit.toJson(
        balanceState,
      );
      final BalanceState? deserialized = balanceCubit.fromJson(
        serialized!,
      );

      expect(deserialized, balanceState);
    });


    group('fetchDataPeriodically', () {
      blocTest<BalanceCubit, BalanceState>(
        'calls getAccountInfoByAddress once',
        build: () => balanceCubit,
        setUp: () {
          when(() => mockLedger.getAccountInfoByAddress(any()),
          ).thenAnswer((_) async => accountInfo);
        },
        act: (BalanceCubit cubit) => cubit.fetch(),
        verify: (_) {
            verify(() =>
                mockLedger.getAccountInfoByAddress(any()),
            ).called(1);
        },
      );

      blocTest<BalanceCubit, BalanceState>(
        'emits [loading, failure] when fetch throws',
        build: () => balanceCubit,
        setUp: () {
          when(() => mockLedger.getAccountInfoByAddress(any()),
          ).thenThrow(balanceException);
        },
        act: (BalanceCubit cubit) => cubit.fetchDataPeriodically(),
          expect: () => <BalanceState>[
            BalanceState(status: TimerStatus.loading),
            BalanceState(
              status: TimerStatus.failure,
              error: balanceException,
            ),
        ],
      );

      blocTest<BalanceCubit, BalanceState>(
        'emits [loading, success] when fetch returns',
        build: () => balanceCubit,
        act: (BalanceCubit cubit) => cubit.fetchDataPeriodically(),
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
