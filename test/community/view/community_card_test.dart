import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app_main;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/community/community.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

import '../../helpers/hydrated_bloc.dart';

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

void main() {
  initHydratedStorage();

  late _MockSharedPrefsService mockSharedPrefsService;
  SharedPrefsService? previousSharedPrefsService;

  setUp(() {
    mockSharedPrefsService = _MockSharedPrefsService();
    when(
      () => mockSharedPrefsService.get(
        any(),
        defaultValue: any<dynamic>(named: 'defaultValue'),
      ),
    ).thenReturn(false);

    previousSharedPrefsService = app_main.sharedPrefsService;
    app_main.sharedPrefsService = mockSharedPrefsService;
  });

  tearDown(() {
    app_main.sharedPrefsService = previousSharedPrefsService;
  });

  group('CommunityCard', () {
    testWidgets('displays all four localized community sections and links', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(width: 900, height: 900, child: CommunityCard()),
          ),
        ),
      );

      expect(find.text('Community'), findsAtLeastNWidgets(1));
      expect(find.text('Websites'), findsOneWidget);
      expect(find.text('Explorers'), findsOneWidget);
      expect(find.text('Social Media'), findsOneWidget);
      expect(find.text('Documentation'), findsOneWidget);

      await tester.tap(find.text('Websites'));
      await tester.pumpAndSettle();
      expect(find.text('Zenon Network'), findsOneWidget);
      expect(find.text('Zenon ORG Community Forum'), findsOneWidget);
      expect(find.text('Zenon Tools'), findsOneWidget);
      expect(find.text('Zenon ORG Community'), findsOneWidget);
      expect(find.text('Zenon Hub'), findsOneWidget);
      await tester.tap(find.text('Websites'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explorers'));
      await tester.pumpAndSettle();
      expect(find.text('Zenon Explorer'), findsOneWidget);
      expect(find.text('Zenon Hub Explorer'), findsOneWidget);
      await tester.tap(find.text('Explorers'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Social Media'));
      await tester.pumpAndSettle();
      expect(find.text('Zenon Twitter'), findsOneWidget);
      expect(find.text('Zenon Discord'), findsOneWidget);
      expect(find.text('Zenon Telegram'), findsOneWidget);
      expect(find.text('Zenon Medium'), findsOneWidget);
      expect(find.text('Zenon Github'), findsOneWidget);
      expect(find.text('Zenon Bitcoin Talk'), findsOneWidget);
      expect(find.text('Zenon Reddit'), findsOneWidget);
      expect(find.text('Zenon Youtube'), findsOneWidget);
      await tester.tap(find.text('Social Media'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Documentation'));
      await tester.pumpAndSettle();
      expect(find.text('Zenon Wiki'), findsOneWidget);
      expect(find.text('ZenonORG Community Wiki'), findsOneWidget);
      expect(find.text('Zenon Whitepaper'), findsOneWidget);
      expect(find.byType(LinkIcon), findsAtLeastNWidgets(3));
    });
  });
}
