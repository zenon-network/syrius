import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockCompleteSwapBloc
    extends MockBloc<CompleteSwapEvent, CompleteSwapState>
    implements CompleteSwapBloc {}

void main() {
  testWidgets('dispatches a complete request to the provided bloc', (
    WidgetTester tester,
  ) async {
    final Hash initialHtlcId = Hash.digest(<int>[1, 2, 3]);
    final HtlcSwap swap = HtlcSwap(
      hashLock: Hash.digest(<int>[4, 5, 6]).toString(),
      initialHtlcId: initialHtlcId.toString(),
      initialHtlcExpirationTime: 3000,
      hashType: htlcHashTypeSha3,
      id: initialHtlcId.toString(),
      chainId: 1,
      type: P2pSwapType.native,
      direction: P2pSwapDirection.outgoing,
      selfAddress: emptyAddress.toString(),
      counterpartyAddress: htlcAddress.toString(),
      fromAmount: BigInt.one,
      fromToken: kZnnCoin,
      fromChain: P2pSwapChain.nom,
      toChain: P2pSwapChain.nom,
      startTime: 1000,
      state: P2pSwapState.active,
      preimage: FormatUtils.encodeHexString(<int>[7, 8, 9]),
    );
    final MockCompleteSwapBloc bloc = MockCompleteSwapBloc();
    when(() => bloc.state).thenReturn(const CompleteSwapInitial());

    await tester.pumpWidget(
      BlocProvider<CompleteSwapBloc>.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CompleteSwapButton(swap: swap),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    verify(
      () => bloc.add(CompleteSwapRequested(swap: swap)),
    ).called(1);
  });
}
