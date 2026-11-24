import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/exchange_rate.dart';

void main() {
  testWidgets('formats and toggles a fractional exchange rate', (
    WidgetTester tester,
  ) async {
    final BigInt oneCoin = BigInt.from(10).pow(kQsrCoin.decimals);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExchangeRate(
            fromAmount: BigInt.from(10) * oneCoin,
            toAmount: oneCoin,
            fromToken: kQsrCoin,
            toToken: kZnnCoin,
          ),
        ),
      ),
    );

    expect(find.text('1 QSR = 0.1 ZNN'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pump();

    expect(find.text('1 ZNN = 10.0 QSR'), findsOneWidget);
  });

  testWidgets('formats a repeating fractional exchange rate', (
    WidgetTester tester,
  ) async {
    final BigInt oneCoin = BigInt.from(10).pow(kQsrCoin.decimals);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExchangeRate(
            fromAmount: BigInt.from(3) * oneCoin,
            toAmount: oneCoin,
            fromToken: kQsrCoin,
            toToken: kZnnCoin,
          ),
        ),
      ),
    );

    expect(find.text('1 QSR = 0.33333 ZNN'), findsOneWidget);
  });
}
