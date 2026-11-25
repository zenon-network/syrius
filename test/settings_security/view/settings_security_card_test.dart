import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_security/settings_security.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

import '../../helpers/hydrated_bloc.dart';

class MockSharedPrefsService extends Mock implements SharedPrefsService {}

void _setClipboardText(String? text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall call,
      ) async {
        if (call.method == 'Clipboard.getData') {
          return text == null ? null : <String, dynamic>{'text': text};
        }
        return null;
      });
}

Finder _panelByHeader(String header) => find.byWidgetPredicate(
  (Widget widget) => widget is CustomExpandablePanel && widget.header == header,
);

void main() {
  initHydratedStorage();

  late MockSharedPrefsService mockPrefs;
  late SharedPrefsService? previousPrefs;

  setUp(() {
    previousPrefs = sharedPrefsService;
    mockPrefs = MockSharedPrefsService();
    when(
      () => mockPrefs.get(any(), defaultValue: any(named: 'defaultValue')),
    ).thenReturn(false);
    sharedPrefsService = mockPrefs;
  });

  tearDown(() {
    sharedPrefsService = previousPrefs;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget buildHarness(SettingsSecurityBloc bloc) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 900,
          child: SettingsSecurityCard(
            bloc: bloc,
            onChangeAutoLockTime: () {},
            onStepperNotificationSeeMorePressed: () {},
          ),
        ),
      ),
    );
  }

  group(
    'SettingsSecurityCard paste & copy controls (Issue #143 / PR #155)',
    () {
      testWidgets(
        'Sign input uses PasteContentButton, enables Sign button on paste, '
        'and keeps CopyToClipboardButton on signature and public key outputs',
        (WidgetTester tester) async {
          _setClipboardText('payload to sign');
          final SettingsSecurityBloc bloc = SettingsSecurityBloc(
            initialAutoLockMinutes: 15,
            initialAutoEraseAttempts: 3,
            prefsService: mockPrefs,
            signBytes: (_) async => Signature('deadbeef', 'cafebabe'),
          );
          addTearDown(bloc.close);

          await tester.pumpWidget(buildHarness(bloc));
          await tester.pumpAndSettle();

          final Finder signPanel = _panelByHeader('Sign');
          await tester.tap(
            find.descendant(of: signPanel, matching: find.text('Sign')).first,
          );
          await tester.pumpAndSettle();

          final Finder signPasteButton = find.descendant(
            of: signPanel,
            matching: find.byType(PasteContentButton),
          );
          expect(signPasteButton, findsOneWidget);
          expect(
            find.descendant(
              of: signPanel,
              matching: find.byType(CopyToClipboardButton),
            ),
            findsNothing,
          );

          final Finder signButtonFinder = find.descendant(
            of: signPanel,
            matching: find.byWidgetPredicate(
              (Widget widget) =>
                  widget is LoadingButton && widget.text == 'Sign',
            ),
          );
          expect(
            tester.widget<LoadingButton>(signButtonFinder).onPressed,
            isNull,
          );

          await tester.tap(signPasteButton);
          await tester.pump();

          expect(find.text('payload to sign'), findsOneWidget);
          expect(
            tester.widget<LoadingButton>(signButtonFinder).onPressed,
            isNotNull,
          );

          await tester.tap(signButtonFinder);
          await tester.pumpAndSettle();

          expect(find.text('deadbeef'), findsOneWidget);
          expect(find.text('cafebabe'), findsOneWidget);
          expect(
            find.descendant(
              of: signPanel,
              matching: find.byType(CopyToClipboardButton),
            ),
            findsNWidgets(2),
          );
        },
      );

      testWidgets(
        'Verify panel uses PasteContentButton on all three inputs and enables '
        'Verify button once all three fields are pasted',
        (WidgetTester tester) async {
          final List<String> clipboardValues = <String>[
            'hello',
            'aabbcc',
            'ddeeff',
          ];
          int pasteIndex = 0;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, (
                MethodCall call,
              ) async {
                if (call.method == 'Clipboard.getData') {
                  return <String, dynamic>{
                    'text': clipboardValues[pasteIndex++],
                  };
                }
                return null;
              });

          final SettingsSecurityBloc bloc = SettingsSecurityBloc(
            initialAutoLockMinutes: 15,
            initialAutoEraseAttempts: 3,
            prefsService: mockPrefs,
          );
          addTearDown(bloc.close);

          await tester.pumpWidget(buildHarness(bloc));
          await tester.pumpAndSettle();

          final Finder verifyPanel = _panelByHeader('Verify');
          await tester.tap(
            find
                .descendant(of: verifyPanel, matching: find.text('Verify'))
                .first,
          );
          await tester.pumpAndSettle();

          final Finder pasteButtons = find.descendant(
            of: verifyPanel,
            matching: find.byType(PasteContentButton),
          );
          expect(pasteButtons, findsNWidgets(3));

          final Finder verifyButtonFinder = find.descendant(
            of: verifyPanel,
            matching: find.byWidgetPredicate(
              (Widget widget) =>
                  widget is LoadingButton && widget.text == 'Verify',
            ),
          );
          expect(
            tester.widget<LoadingButton>(verifyButtonFinder).onPressed,
            isNull,
          );

          await tester.tap(pasteButtons.at(0));
          await tester.pump();
          await tester.tap(pasteButtons.at(1));
          await tester.pump();
          await tester.tap(pasteButtons.at(2));
          await tester.pump();

          expect(find.text('hello'), findsOneWidget);
          expect(find.text('aabbcc'), findsOneWidget);
          expect(find.text('ddeeff'), findsOneWidget);
          expect(
            tester.widget<LoadingButton>(verifyButtonFinder).onPressed,
            isNotNull,
          );
        },
      );

      testWidgets('Verify file panel uses PasteContentButton on both inputs', (
        WidgetTester tester,
      ) async {
        final SettingsSecurityBloc bloc = SettingsSecurityBloc(
          initialAutoLockMinutes: 15,
          initialAutoEraseAttempts: 3,
          prefsService: mockPrefs,
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(buildHarness(bloc));
        await tester.pumpAndSettle();

        final Finder verifyFilePanel = _panelByHeader('Verify file');
        await tester.tap(
          find
              .descendant(
                of: verifyFilePanel,
                matching: find.text('Verify file'),
              )
              .first,
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: verifyFilePanel,
            matching: find.byType(PasteContentButton),
          ),
          findsNWidgets(2),
        );
      });
    },
  );
}
