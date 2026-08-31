import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';

void main() {
  group('TokenMetricsStep', () {
    late TextEditingController maxSupplyController;
    late TextEditingController totalSupplyController;
    late ValueNotifier<NewTokenData> tokenData;

    setUp(() {
      maxSupplyController = TextEditingController();
      totalSupplyController = TextEditingController();
      tokenData = ValueNotifier<NewTokenData>(
        NewTokenData(
          address: 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
          tokenName: 'Token',
          tokenSymbol: 'TKN',
          tokenDomain: 'example.com',
          totalSupply: BigInt.zero,
          decimals: 0,
          maxSupply: BigInt.zero,
          isMintable: false,
          isBurnable: false,
          isUtility: true,
        ),
      );
    });

    tearDown(() {
      maxSupplyController.dispose();
      totalSupplyController.dispose();
      tokenData.dispose();
    });

    testWidgets(
      'revalidates supply when decimals change',
      (WidgetTester tester) async {
        await _pumpTokenMetricsStep(
          tester,
          maxSupplyController: maxSupplyController,
          totalSupplyController: totalSupplyController,
          tokenData: tokenData,
        );

        _changeDecimalsSlider(tester, 1);
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('token_total_supply_field')),
          '1.1',
        );
        await tester.pump();

        expect(_continueButton(tester).onPressed, isNotNull);

        _changeDecimalsSlider(tester, 0);
        await tester.pump();

        expect(_continueButton(tester).onPressed, isNull);
      },
    );
  });
}

void _changeDecimalsSlider(WidgetTester tester, double value) {
  final Slider slider = tester.widget<Slider>(
    find.byKey(const Key('token_decimals_slider')),
  );
  slider.onChanged!(value);
}

OutlinedButton _continueButton(WidgetTester tester) {
  return tester.widget<OutlinedButton>(
    find.descendant(
      of: find.byKey(const Key('token_metrics_next_button')),
      matching: find.byType(OutlinedButton),
    ),
  );
}

Future<void> _pumpTokenMetricsStep(
  WidgetTester tester, {
  required TextEditingController maxSupplyController,
  required TextEditingController totalSupplyController,
  required ValueNotifier<NewTokenData> tokenData,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 700,
          height: 500,
          child: ValueListenableBuilder<NewTokenData>(
            valueListenable: tokenData,
            builder: (_, __, ___) {
              return TokenMetricsStep(
                maxSupplyController: maxSupplyController,
                onBackPressed: () {},
                onContinuePressed: () {},
                tokenData: tokenData,
                totalSupplyController: totalSupplyController,
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
