//ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/transfer_widget_balance/transfer_widget_balance_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}
class MockWsClient extends Mock implements WsClient {}
class MockLedger extends Mock implements LedgerApi {}
class MockAccountInfo extends Mock implements AccountInfo {}
class FakeAddress extends Fake implements Address {}

void main() {
  registerFallbackValue(FakeAddress());

  late MockZenon mockZenon;
  late MockLedger mockLedger;
  late MockWsClient mockWsClient;
  late TransferWidgetBalanceBloc bloc;

  setUp(() {
    mockZenon = MockZenon();
    mockLedger = MockLedger();
    mockWsClient = MockWsClient();
    when(() => mockZenon.wsClient).thenReturn(mockWsClient);
    when(() => mockZenon.ledger).thenReturn(mockLedger);
    bloc = TransferWidgetBalanceBloc(
        zenon: mockZenon,
        list: <String?>[emptyAddress.toString()],
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('TransferWidgetsBalanceBloc', () {
    final String testAddress = emptyAddress.toString();
    final MockAccountInfo mockAccountInfo = MockAccountInfo();
    final Exception exception = Exception();

    test('initial state is correct', () {
      expect(bloc.state.status, TransferWidgetBalanceStatus.initial);
    });

    blocTest<TransferWidgetBalanceBloc, TransferWidgetBalanceState>(
      'emits [loading, success] with data on successful fetch',
      setUp: () {
        when(() => mockAccountInfo.address).thenReturn(testAddress);
        when(() => mockLedger.getAccountInfoByAddress(any()))
            .thenAnswer((_) async => mockAccountInfo);
      },
      build: () => bloc,
      act: (TransferWidgetBalanceBloc bloc) => bloc.add(FetchBalances()),
      expect: () => <TransferWidgetBalanceState>[
        TransferWidgetBalanceState(status: TransferWidgetBalanceStatus.loading),
        TransferWidgetBalanceState(
          status: TransferWidgetBalanceStatus.success,
          data: <String, AccountInfo>{testAddress: mockAccountInfo},
        ),
      ],
    );

    blocTest<TransferWidgetBalanceBloc, TransferWidgetBalanceState>(
      'emits [loading, failure] when fetching balances fails',
      setUp: () {
        when(() => mockZenon.ledger.getAccountInfoByAddress(any()))
            .thenThrow(exception);
      },
      build: () => bloc,
      act: (TransferWidgetBalanceBloc bloc) => bloc.add(FetchBalances()),
      expect: () => <TransferWidgetBalanceState>[
        TransferWidgetBalanceState(status: TransferWidgetBalanceStatus.loading),
        TransferWidgetBalanceState(
          status: TransferWidgetBalanceStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
