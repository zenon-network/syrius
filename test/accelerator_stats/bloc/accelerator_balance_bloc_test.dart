import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_stats/accelerator_stats.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockLedgerApi extends Mock implements LedgerApi {}

class _MockAccountInfo extends Mock implements AccountInfo {}

void main() {
  group('AcceleratorBalanceBloc', () {
    late _MockZenon zenon;
    late _MockLedgerApi ledgerApi;
    late _MockAccountInfo accountInfo;

    setUp(() {
      zenon = _MockZenon();
      ledgerApi = _MockLedgerApi();
      accountInfo = _MockAccountInfo();
      when(() => zenon.ledger).thenReturn(ledgerApi);
    });

    test('initial state is AcceleratorBalanceInitial', () async {
      final AcceleratorBalanceBloc bloc = AcceleratorBalanceBloc(zenon: zenon);
      expect(bloc.state, const AcceleratorBalanceInitial());
      await bloc.close();
    });

    blocTest<AcceleratorBalanceBloc, AcceleratorBalanceState>(
      'emits [loading, populated] when ZNN balance is positive',
      setUp: () {
        when(() => accountInfo.znn()).thenReturn(BigInt.from(100));
        when(() => accountInfo.qsr()).thenReturn(BigInt.zero);
        when(
          () => ledgerApi.getAccountInfoByAddress(acceleratorAddress),
        ).thenAnswer((_) async => accountInfo);
      },
      build: () => AcceleratorBalanceBloc(zenon: zenon),
      act: (AcceleratorBalanceBloc bloc) =>
          bloc.add(const AcceleratorBalanceRequested()),
      expect: () => <AcceleratorBalanceState>[
        const AcceleratorBalanceLoading(),
        AcceleratorBalancePopulated(accountInfo: accountInfo),
      ],
    );

    blocTest<AcceleratorBalanceBloc, AcceleratorBalanceState>(
      'emits [loading, failure(AcceleratorFundEmptyException)] when fund is '
      'empty',
      setUp: () {
        when(() => accountInfo.znn()).thenReturn(BigInt.zero);
        when(() => accountInfo.qsr()).thenReturn(BigInt.zero);
        when(
          () => ledgerApi.getAccountInfoByAddress(acceleratorAddress),
        ).thenAnswer((_) async => accountInfo);
      },
      build: () => AcceleratorBalanceBloc(zenon: zenon),
      act: (AcceleratorBalanceBloc bloc) =>
          bloc.add(const AcceleratorBalanceRequested()),
      expect: () => <AcceleratorBalanceState>[
        const AcceleratorBalanceLoading(),
        AcceleratorBalanceFailure(exception: AcceleratorFundEmptyException()),
      ],
    );

    blocTest<AcceleratorBalanceBloc, AcceleratorBalanceState>(
      'emits [loading, failure(FailureException)] when RPC throws',
      setUp: () {
        when(
          () => ledgerApi.getAccountInfoByAddress(acceleratorAddress),
        ).thenThrow(Exception('rpc error'));
      },
      build: () => AcceleratorBalanceBloc(zenon: zenon),
      act: (AcceleratorBalanceBloc bloc) =>
          bloc.add(const AcceleratorBalanceRequested()),
      expect: () => <Matcher>[
        isA<AcceleratorBalanceLoading>(),
        isA<AcceleratorBalanceFailure>().having(
          (AcceleratorBalanceFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
