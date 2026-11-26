import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/l10n/app_localizations_resolver.dart';

class _CustomAppLocalizations extends AppLocalizationsEn {
  _CustomAppLocalizations() : super('en');

  @override
  String get receiveTransactionFailed => '[CUSTOM] receiveTransactionFailed';
}

class _CustomL10nDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _CustomL10nDelegate(this.l10n);

  final AppLocalizations l10n;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(l10n);

  @override
  bool shouldReload(covariant _CustomL10nDelegate old) => old.l10n != l10n;
}

void main() {
  group('resolveAppLocalizations', () {
    test(
      'resolves without BuildContext and falls back for unsupported locales',
      () {
        final AppLocalizations defaultL10n = resolveAppLocalizations();
        expect(
          defaultL10n.receiveTransactionFailed,
          'Receive transaction failed',
        );

        final AppLocalizations explicitEn = resolveAppLocalizations(
          locale: const Locale('en', 'US'),
        );
        expect(
          explicitEn.receiveTransactionFailed,
          'Receive transaction failed',
        );

        final AppLocalizations unsupportedFallback = resolveAppLocalizations(
          locale: const Locale('fr', 'FR'),
        );
        expect(
          unsupportedFallback.receiveTransactionFailed,
          'Receive transaction failed',
        );
      },
    );

    testWidgets('uses AppLocalizations from BuildContext when provided', (
      WidgetTester tester,
    ) async {
      final _CustomAppLocalizations custom = _CustomAppLocalizations();
      late AppLocalizations resolved;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            _CustomL10nDelegate(custom),
            ...AppLocalizations.localizationsDelegates.skip(1),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              resolved = resolveAppLocalizations(context: context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        resolved.receiveTransactionFailed,
        '[CUSTOM] receiveTransactionFailed',
      );
    });
  });
}
