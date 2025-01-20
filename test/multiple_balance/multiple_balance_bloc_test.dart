import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/failure_exception.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';

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
    late MultipleBalanceBloc bloc;
    late String testAddress;
    late BalanceInfoListItem balanceInfoListItem;
    late AccountInfo accountInfo;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockLedger = MockLedger();
      mockWsClient = MockWsClient();
      testAddress = emptyAddress.toString();
      exception = FailureException();

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
      bloc = MultipleBalanceBloc(
        zenon: mockZenon,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('failure equality', () {
      final MultipleBalanceState failure = MultipleBalanceState(
        status: MultipleBalanceStatus.failure,
        error: exception,
      );

      expect(
        failure,
        MultipleBalanceState(
          status: MultipleBalanceStatus.failure,
          error: FailureException(),
        ),
      );
    });

    test('initial state is correct', () {
      expect(bloc.state.status, MultipleBalanceStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const MultipleBalanceState initialState = MultipleBalanceState();

        final Map<String, dynamic>? serialized = bloc.toJson(
          initialState,
        );
        final MultipleBalanceState? deserialized = bloc.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const MultipleBalanceState loadingState = MultipleBalanceState(
          status: MultipleBalanceStatus.loading,
        );

        final Map<String, dynamic>? serialized = bloc.toJson(
          loadingState,
        );
        final MultipleBalanceState? deserialized = bloc.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final MultipleBalanceState successState = MultipleBalanceState(
          status: MultipleBalanceStatus.success,
          data: <String, AccountInfo>{testAddress: accountInfo},
        );

        final Map<String, dynamic>? serialized = bloc.toJson(
          successState,
        );
        final MultipleBalanceState? deserialized = bloc.fromJson(
          serialized!,
        );
        expect(deserialized, isA<MultipleBalanceState>());
        expect(deserialized!.status, equals(MultipleBalanceStatus.success));
        expect(deserialized.data, isA<Map<String, AccountInfo>>());
      });

      test('can (de)serialize failure state', () {
        final MultipleBalanceState failureState = MultipleBalanceState(
          status: MultipleBalanceStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = bloc.toJson(
          failureState,
        );
        final MultipleBalanceState? deserialized = bloc.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<MultipleBalanceBloc, MultipleBalanceState>(
      'emits [loading, success] with data on successful fetch',
      build: () => bloc,
      act: (MultipleBalanceBloc bloc) => bloc.add(
        MultipleBalanceFetch(
          addresses: <String>[emptyAddress.toString()],
        ),
      ),
      expect: () => <MultipleBalanceState>[
        const MultipleBalanceState(status: MultipleBalanceStatus.loading),
        MultipleBalanceState(
          status: MultipleBalanceStatus.success,
          data: <String, AccountInfo>{testAddress: accountInfo},
        ),
      ],
    );

    blocTest<MultipleBalanceBloc, MultipleBalanceState>(
      'emits [loading, failure] when fetching balances fails',
      setUp: () {
        when(() => mockLedger.getAccountInfoByAddress(any()))
            .thenThrow(exception);
      },
      build: () => bloc,
      act: (MultipleBalanceBloc bloc) => bloc.add(
        MultipleBalanceFetch(
          addresses: <String>[emptyAddress.toString()],
        ),
      ),
      expect: () => <MultipleBalanceState>[
        const MultipleBalanceState(status: MultipleBalanceStatus.loading),
        MultipleBalanceState(
          status: MultipleBalanceStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
