import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/export_wallet/export_wallet.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

void main() {
  group('ExportWalletBloc', () {
    late List<WalletNotification> notifications;
    late List<String> errorTitles;
    late String? savedFilePath;

    setUp(() {
      notifications = <WalletNotification>[];
      errorTitles = <String>[];
      savedFilePath = null;
    });

    ExportWalletBloc buildBloc({
      Future<String?> Function({required String suggestedName})? pickSavePath,
      Future<void> Function({
        required String seed,
        required String password,
        required String filePath,
      })?
      saveKeyStore,
    }) => ExportWalletBloc(
      pickSavePath:
          pickSavePath ??
          ({required String suggestedName}) async => '/tmp/$suggestedName',
      saveKeyStore:
          saveKeyStore ??
          ({
            required String seed,
            required String password,
            required String filePath,
          }) async {
            savedFilePath = filePath;
          },
      addNotification: (WalletNotification notification) async {
        notifications.add(notification);
      },
      reportError: (Object error, String title) async {
        errorTitles.add(title);
      },
      now: () => DateTime(2026, 11, 24, 10, 30),
    );

    blocTest<ExportWalletBloc, ExportWalletState>(
      'returns to initial when user cancels file save dialog',
      build: () => buildBloc(
        pickSavePath: ({required String suggestedName}) async => null,
      ),
      act: (ExportWalletBloc bloc) => bloc.add(
        ExportWalletRequested(
          seed: 'seed words',
          password: 'Password1!',
          backupWalletFlow: true,
          successTitle: 'Exported',
          successDetailsBuilder: (String p) => 'Saved to $p',
          errorTitle: 'Export failed',
        ),
      ),
      expect: () => const <ExportWalletState>[
        ExportWalletLoading(),
        ExportWalletInitial(),
      ],
      verify: (_) {
        expect(savedFilePath, isNull);
        expect(notifications, isEmpty);
      },
    );

    blocTest<ExportWalletBloc, ExportWalletState>(
      'saves keystore and sends notification in backupWalletFlow',
      build: buildBloc,
      act: (ExportWalletBloc bloc) => bloc.add(
        ExportWalletRequested(
          seed: 'seed words',
          password: 'Password1!',
          backupWalletFlow: true,
          successTitle: 'Exported',
          successDetailsBuilder: (String p) => 'Saved to $p',
          errorTitle: 'Export failed',
        ),
      ),
      expect: () => <Matcher>[
        isA<ExportWalletLoading>(),
        isA<ExportWalletSuccess>().having(
          (ExportWalletSuccess s) => s.backupWalletFlow,
          'backupWalletFlow',
          true,
        ),
      ],
      verify: (_) {
        expect(savedFilePath, isNotNull);
        expect(notifications, hasLength(1));
        expect(notifications.single.details, contains(savedFilePath));
      },
    );

    blocTest<ExportWalletBloc, ExportWalletState>(
      'saves keystore without backup notification during onboarding flow',
      build: buildBloc,
      act: (ExportWalletBloc bloc) => bloc.add(
        ExportWalletRequested(
          seed: 'seed words',
          password: 'Password1!',
          backupWalletFlow: false,
          successTitle: 'Exported',
          successDetailsBuilder: (String p) => 'Saved to $p',
          errorTitle: 'Export failed',
        ),
      ),
      expect: () => <Matcher>[
        isA<ExportWalletLoading>(),
        isA<ExportWalletSuccess>().having(
          (ExportWalletSuccess s) => s.backupWalletFlow,
          'backupWalletFlow',
          false,
        ),
      ],
      verify: (_) {
        expect(savedFilePath, isNotNull);
        expect(notifications, isEmpty);
      },
    );

    blocTest<ExportWalletBloc, ExportWalletState>(
      'reports error and emits failure when saveKeyStore throws',
      build: () => buildBloc(
        saveKeyStore:
            ({
              required String seed,
              required String password,
              required String filePath,
            }) async => throw StateError('permission denied'),
      ),
      act: (ExportWalletBloc bloc) => bloc.add(
        ExportWalletRequested(
          seed: 'seed words',
          password: 'Password1!',
          backupWalletFlow: true,
          successTitle: 'Exported',
          successDetailsBuilder: (String p) => 'Saved to $p',
          errorTitle: 'Export failed',
        ),
      ),
      expect: () => <Matcher>[
        isA<ExportWalletLoading>(),
        isA<ExportWalletFailure>(),
      ],
      verify: (_) {
        expect(errorTitles, <String>['Export failed']);
      },
    );
  });

  group('ExportWalletInfoScreen', () {
    testWidgets('enables Continue only after confirming backup checkbox', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExportWalletInfoScreen('test seed phrase'),
        ),
      );
      await tester.pumpAndSettle();

      final Finder continueButtonFinder = find.byWidgetPredicate(
        (Widget widget) =>
            widget is OnboardingButton && widget.text == 'Continue',
      );
      expect(
        tester.widget<OnboardingButton>(continueButtonFinder).onPressed,
        isNull,
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(
        tester.widget<OnboardingButton>(continueButtonFinder).onPressed,
        isNotNull,
      );
    });
  });

  group('ExportWalletPasswordScreen', () {
    testWidgets(
      'enables Export button on matching strong passwords and updates '
      'exported seeds notifier during onboarding flow',
      (WidgetTester tester) async {
        final ValueNotifier<List<String>> exportedSeeds =
            ValueNotifier<List<String>>(<String>[]);
        addTearDown(exportedSeeds.dispose);

        final ExportWalletBloc bloc = ExportWalletBloc(
          pickSavePath: ({required String suggestedName}) async =>
              '/tmp/backup.json',
          saveKeyStore:
              ({
                required String seed,
                required String password,
                required String filePath,
              }) async {},
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          ChangeNotifierProvider<ValueNotifier<List<String>>>.value(
            value: exportedSeeds,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (BuildContext context) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ExportWalletPasswordScreen(
                              'test seed phrase',
                              bloc: bloc,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final Finder exportButtonFinder = find.byWidgetPredicate(
          (Widget widget) =>
              widget is OnboardingButton && widget.text == 'Export',
        );
        expect(
          tester.widget<OnboardingButton>(exportButtonFinder).onPressed,
          isNull,
        );

        final Finder textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'StrongPass1!');
        await tester.enterText(textFields.at(1), 'StrongPass1!');
        await tester.pump();

        expect(
          tester.widget<OnboardingButton>(exportButtonFinder).onPressed,
          isNotNull,
        );

        await tester.tap(exportButtonFinder);
        await tester.pumpAndSettle();

        expect(exportedSeeds.value, <String>['test seed phrase']);
      },
    );
  });
}
