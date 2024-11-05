import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/transfer_balance/transfer_balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}
class MockWsClient extends Mock implements WsClient {}
class MockLedger extends Mock implements LedgerApi {}
class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  registerFallbackValue(FakeAddress());

  group('TransferBalanceBloc', () {
  late MockZenon mockZenon;
  late MockLedger mockLedger;
  late MockWsClient mockWsClient;
  late TransferBalanceBloc bloc;
  late String testAddress;
  late BalanceInfoListItem balanceInfoListItem;
  late AccountInfo accountInfo;
  late CubitFailureException exception;

  setUp(() {
    mockZenon = MockZenon();
    mockLedger = MockLedger();
    mockWsClient = MockWsClient();
    testAddress = emptyAddress.toString();
    exception = CubitFailureException();

    balanceInfoListItem = BalanceInfoListItem(
      token: kZnnCoin,
      balance: BigInt.from(5),
    );

    accountInfo = AccountInfo(
      address: emptyAddress.toString(),
      blockCount: 1,
      balanceInfoList: <BalanceInfoListItem>[balanceInfoListItem],
    );

    when(() => mockZenon.wsClient).thenReturn(mockWsClient);
    when(() => mockZenon.ledger).thenReturn(mockLedger);
    when(() => mockLedger.getAccountInfoByAddress(any()))
        .thenAnswer((_) async => accountInfo);
    bloc = TransferBalanceBloc(
        zenon: mockZenon,
        addressList: <String?>[emptyAddress.toString()],
    );
  });

  tearDown(() {
    bloc.close();
  });

    test('initial state is correct', () {
      expect(bloc.state.status, TransferBalanceStatus.initial);
    });

  group('fromJson/toJson', () {
    test('can (de)serialize initial state', () {
      const TransferBalanceState initialState = TransferBalanceState();

      final Map<String, dynamic>? serialized = bloc.toJson(
        initialState,
      );
      final TransferBalanceState? deserialized =
      bloc.fromJson(serialized!);

      expect(deserialized, equals(initialState));
    });

    test('can (de)serialize loading state', () {
      const TransferBalanceState loadingState = TransferBalanceState(
        status: TransferBalanceStatus.loading,
      );

      final Map<String, dynamic>? serialized = bloc.toJson(
        loadingState,
      );
      final TransferBalanceState? deserialized =
      bloc.fromJson(
        serialized!,
      );
      expect(deserialized, equals(loadingState));
    });

    test('can (de)serialize success state', () {
      final TransferBalanceState successState = TransferBalanceState(
        status: TransferBalanceStatus.success,
        data: <String, AccountInfo>{testAddress : accountInfo},
      );

      final Map<String, dynamic>? serialized = bloc.toJson(
        successState,
      );
      final TransferBalanceState? deserialized =
      bloc.fromJson(
        serialized!,
      );
      expect(deserialized, isA<TransferBalanceState>());
      expect(deserialized!.status, equals(TransferBalanceStatus.success));
      expect(deserialized.data, isA<Map<String, AccountInfo>>());
    });

    test('can (de)serialize failure state', () {
      final TransferBalanceState failureState = TransferBalanceState(
        status: TransferBalanceStatus.failure,
        error: exception,
      );

      final Map<String, dynamic>? serialized = bloc.toJson(
        failureState,
      );
      final TransferBalanceState? deserialized =
      bloc.fromJson(
        serialized!,
      );
      expect(deserialized, equals(failureState));
    });
  });

    blocTest<TransferBalanceBloc, TransferBalanceState>(
      'emits [loading, success] with data on successful fetch',
      build: () => bloc,
      act: (TransferBalanceBloc bloc) => bloc.add(FetchBalances()),
      expect: () => <TransferBalanceState>[
        const TransferBalanceState(status: TransferBalanceStatus.loading),
        TransferBalanceState(
          status: TransferBalanceStatus.success,
          data: <String, AccountInfo>{testAddress: accountInfo},
        ),
      ],
    );

    blocTest<TransferBalanceBloc, TransferBalanceState>(
      'emits [loading, failure] when fetching balances fails',
      setUp: () {
        when(() => mockZenon.ledger.getAccountInfoByAddress(any()))
            .thenThrow(exception);
      },
      build: () => bloc,
      act: (TransferBalanceBloc bloc) => bloc.add(FetchBalances()),
      expect: () => <TransferBalanceState>[
        const TransferBalanceState(status: TransferBalanceStatus.loading),
        TransferBalanceState(
          status: TransferBalanceStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
