import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/transfer_widget_balance/transfer_widget_balance_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

//Cubit not testable: use of global variable interferes with testing

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
    bloc = TransferWidgetBalanceBloc(mockZenon);
  });

  tearDown(() {
    bloc.close();
  });

  group('TransferWidgetsBalanceBloc', () {
    final testAddress = emptyAddress.toString();
    final mockAccountInfo = MockAccountInfo();
    final exception = Exception();

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
      act: (bloc) => bloc.add(FetchBalances()),
      expect: () => [
        const TransferWidgetBalanceState(status: TransferWidgetBalanceStatus.loading),
        TransferWidgetBalanceState(
          status: TransferWidgetBalanceStatus.success,
          data: {testAddress: mockAccountInfo},
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
      act: (bloc) => bloc.add(FetchBalances()),
      expect: () => [
        const TransferWidgetBalanceState(
            status: TransferWidgetBalanceStatus.loading),
        TransferWidgetBalanceState(
          status: TransferWidgetBalanceStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}