import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockJoinP2pSwapBloc
    extends MockBloc<JoinP2pSwapEvent, JoinP2pSwapState>
    implements JoinP2pSwapBloc {}

void main() {
  testWidgets('dispatches a join request to the provided bloc', (
    WidgetTester tester,
  ) async {
    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final HtlcInfo initialHtlc = HtlcInfo(
      id: htlcId,
      timeLocked: htlcAddress,
      hashLocked: emptyAddress,
      tokenStandard: kQsrCoin.tokenStandard,
      amount: BigInt.one,
      expirationTime: 3000,
      hashType: htlcHashTypeSha3,
      keyMaxSize: htlcPreimageMaxLength,
      hashLock: <int>[4, 5, 6],
    );
    final MockJoinP2pSwapBloc bloc = MockJoinP2pSwapBloc();
    when(() => bloc.state).thenReturn(const JoinP2pSwapInitial());

    await tester.pumpWidget(
      BlocProvider<JoinP2pSwapBloc>.value(
        value: bloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JoinSwapButton(
              fromAmount: '1',
              fromToken: kZnnCoin,
              initialHtlc: initialHtlc,
              isEnabled: true,
              toToken: kQsrCoin,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    verify(
      () => bloc.add(
        JoinP2pSwapRequested(
          initialHtlc: initialHtlc,
          fromToken: kZnnCoin,
          toToken: kQsrCoin,
          fromAmount: BigInt.from(100000000),
          swapType: P2pSwapType.native,
          fromChain: P2pSwapChain.nom,
          toChain: P2pSwapChain.nom,
        ),
      ),
    ).called(1);
  });
}
