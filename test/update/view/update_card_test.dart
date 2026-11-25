import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app_main;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/update/update.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';

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

  group('UpdateCard', () {
    testWidgets('renders localized labels and invokes update callback on tap', (
      WidgetTester tester,
    ) async {
      int pressedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: UpdateCard(
                onUpdatePressed: () {
                  pressedCount++;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Update'), findsAtLeastNWidgets(1));
      expect(find.text('Check update'), findsOneWidget);

      await tester.tap(find.text('Check update'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Update'));
      await tester.pump();

      expect(pressedCount, equals(1));
    });
  });
}
