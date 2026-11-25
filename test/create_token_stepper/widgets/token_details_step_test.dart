import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  group('TokenDetailsStep', () {
    late TextEditingController tokenNameController;
    late TextEditingController tokenSymbolController;
    late TextEditingController tokenDomainController;
    late ValueNotifier<NewTokenData> tokenData;

    setUp(() {
      tokenNameController = TextEditingController();
      tokenSymbolController = TextEditingController();
      tokenDomainController = TextEditingController();
      tokenData = ValueNotifier<NewTokenData>(
        NewTokenData.initial(
          address: 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
        ),
      );
    });

    tearDown(() {
      tokenNameController.dispose();
      tokenSymbolController.dispose();
      tokenDomainController.dispose();
      tokenData.dispose();
    });

    testWidgets('starts with no visible field errors and continue disabled', (
      WidgetTester tester,
    ) async {
      await _pumpTokenDetailsStep(
        tester,
        tokenNameController: tokenNameController,
        tokenSymbolController: tokenSymbolController,
        tokenDomainController: tokenDomainController,
        tokenData: tokenData,
      );

      expect(_fieldError(tester, const Key('token_name_field')), isNull);
      expect(_fieldError(tester, const Key('token_symbol_field')), isNull);
      expect(_fieldError(tester, const Key('token_domain_field')), isNull);
      expect(_continueButton(tester).onPressed, isNull);
    });

    testWidgets(
      'validates token name against protocol character and length limits',
      (WidgetTester tester) async {
        await _pumpTokenDetailsStep(
          tester,
          tokenNameController: tokenNameController,
          tokenSymbolController: tokenSymbolController,
          tokenDomainController: tokenDomainController,
          tokenData: tokenData,
        );
        final AppLocalizations l10n = _l10n(tester);

        // Valid name with alphanumeric characters and single separators.
        await tester.enterText(
          find.byKey(const Key('token_name_field')),
          'My-Token_1.0',
        );
        await tester.pump();
        expect(_fieldError(tester, const Key('token_name_field')), isNull);

        // Invalid names: space, leading/trailing/consecutive separators, symbol.
        for (final String invalidName in <String>[
          'My Token',
          '-Token',
          'Token-',
          'My--Token',
          '${'a' * 38}!',
        ]) {
          await tester.enterText(
            find.byKey(const Key('token_name_field')),
            invalidName,
          );
          await tester.pump();
          expect(
            _fieldError(tester, const Key('token_name_field')),
            l10n.tokenNameAllowedCharacters,
          );
        }

        // Exceeds protocol max length (40).
        await tester.enterText(
          find.byKey(const Key('token_name_field')),
          'a' * (tokenNameMaxLength + 1),
        );
        await tester.pump();
        expect(
          _fieldError(tester, const Key('token_name_field')),
          l10n.tokenNameMaxLength(tokenNameMaxLength),
        );
      },
    );

    testWidgets(
      'validates token symbol with localized messages instead of raw regex',
      (WidgetTester tester) async {
        await _pumpTokenDetailsStep(
          tester,
          tokenNameController: tokenNameController,
          tokenSymbolController: tokenSymbolController,
          tokenDomainController: tokenDomainController,
          tokenData: tokenData,
        );
        final AppLocalizations l10n = _l10n(tester);

        // Lowercase and non-alphanumeric characters are rejected with a clear
        // localized message (not a raw regex string).
        for (final String invalidSymbol in <String>['tkn', 'TK-N', 'TKN!']) {
          await tester.enterText(
            find.byKey(const Key('token_symbol_field')),
            invalidSymbol,
          );
          await tester.pump();
          expect(
            _fieldError(tester, const Key('token_symbol_field')),
            l10n.tokenSymbolUppercaseAlphanumericOnly,
          );
        }

        // Exceeds protocol max length (10).
        await tester.enterText(
          find.byKey(const Key('token_symbol_field')),
          'A' * (tokenSymbolMaxLength + 1),
        );
        await tester.pump();
        expect(
          _fieldError(tester, const Key('token_symbol_field')),
          l10n.tokenSymbolMaxLength(tokenSymbolMaxLength),
        );

        // Reserved symbols ZNN and QSR.
        for (final String reservedSymbol in tokenSymbolExceptions) {
          await tester.enterText(
            find.byKey(const Key('token_symbol_field')),
            reservedSymbol,
          );
          await tester.pump();
          expect(
            _fieldError(tester, const Key('token_symbol_field')),
            l10n.tokenSymbolCannotBe(tokenSymbolExceptions.join(', ')),
          );
        }

        // Valid uppercase alphanumeric symbol.
        await tester.enterText(
          find.byKey(const Key('token_symbol_field')),
          'TKN1',
        );
        await tester.pump();
        expect(_fieldError(tester, const Key('token_symbol_field')), isNull);
      },
    );

    testWidgets(
      'validates token domain against protocol domain rule and rejects URLs '
      'with protocol schemes',
      (WidgetTester tester) async {
        await _pumpTokenDetailsStep(
          tester,
          tokenNameController: tokenNameController,
          tokenSymbolController: tokenSymbolController,
          tokenDomainController: tokenDomainController,
          tokenData: tokenData,
        );
        final AppLocalizations l10n = _l10n(tester);

        for (final String invalidDomain in <String>[
          'https://testing.com',
          'http://testing.com',
          'testing.com/path',
          'testing',
          '-testing.com',
        ]) {
          await tester.enterText(
            find.byKey(const Key('token_domain_field')),
            invalidDomain,
          );
          await tester.pump();
          expect(
            _fieldError(tester, const Key('token_domain_field')),
            l10n.enterValidDomainWithoutProtocol,
          );
        }

        // Exceeds protocol max length (128).
        final String tooLongDomain = '${'a' * 62}.${'b' * 62}.com';
        await tester.enterText(
          find.byKey(const Key('token_domain_field')),
          tooLongDomain,
        );
        await tester.pump();
        expect(
          _fieldError(tester, const Key('token_domain_field')),
          l10n.tokenDomainMaxLength(128),
        );

        for (final String validDomain in <String>[
          'testing.com',
          'sub.my-token.network',
        ]) {
          await tester.enterText(
            find.byKey(const Key('token_domain_field')),
            validDomain,
          );
          await tester.pump();
          expect(_fieldError(tester, const Key('token_domain_field')), isNull);
        }
      },
    );

    testWidgets(
      'enables continue and updates tokenData only when all fields are valid',
      (WidgetTester tester) async {
        int continueCalls = 0;

        await _pumpTokenDetailsStep(
          tester,
          tokenNameController: tokenNameController,
          tokenSymbolController: tokenSymbolController,
          tokenDomainController: tokenDomainController,
          tokenData: tokenData,
          onContinuePressed: () => continueCalls++,
        );

        await tester.enterText(
          find.byKey(const Key('token_name_field')),
          'My-Token_1',
        );
        await tester.enterText(
          find.byKey(const Key('token_symbol_field')),
          'MTK1',
        );
        await tester.enterText(
          find.byKey(const Key('token_domain_field')),
          'https://testing.com',
        );
        await tester.pump();
        expect(_continueButton(tester).onPressed, isNull);

        await tester.enterText(
          find.byKey(const Key('token_domain_field')),
          'testing.com',
        );
        await tester.pump();
        expect(_continueButton(tester).onPressed, isNotNull);

        await tester.tap(find.byKey(const Key('token_details_next_button')));
        await tester.pump();

        expect(continueCalls, 1);
        expect(tokenData.value.tokenName, 'My-Token_1');
        expect(tokenData.value.tokenSymbol, 'MTK1');
        expect(tokenData.value.tokenDomain, 'testing.com');
      },
    );
  });
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(TokenDetailsStep)))!;

String? _fieldError(WidgetTester tester, Key fieldKey) =>
    tester.widget<TextField>(find.byKey(fieldKey)).decoration?.errorText;

OutlinedButton _continueButton(WidgetTester tester) => tester
    .widget<OutlinedButton>(find.byKey(const Key('token_details_next_button')));

Future<void> _pumpTokenDetailsStep(
  WidgetTester tester, {
  required TextEditingController tokenNameController,
  required TextEditingController tokenSymbolController,
  required TextEditingController tokenDomainController,
  required ValueNotifier<NewTokenData> tokenData,
  VoidCallback? onBackPressed,
  VoidCallback? onContinuePressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 700,
          height: 500,
          child: TokenDetailsStep(
            onBackPressed: onBackPressed ?? () {},
            onContinuePressed: onContinuePressed ?? () {},
            tokenData: tokenData,
            tokenDomainController: tokenDomainController,
            tokenNameController: tokenNameController,
            tokenSymbolController: tokenSymbolController,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
