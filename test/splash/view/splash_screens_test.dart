import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

void main() {
  group('SplashScreen', () {
    testWidgets(
      'triggers initialization once and navigates to AccessWalletScreen when '
      'no wallet path is stored',
      (WidgetTester tester) async {
        int initCount = 0;
        final Completer<LottieComposition> compositionCompleter =
            Completer<LottieComposition>();
        final SplashBloc bloc = SplashBloc(
          getWalletPath: () => null,
          getSelectedNode: () => null,
        );

        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routes: <String, WidgetBuilder>{
                AccessWalletScreen.route: (_) =>
                    const Text('access-wallet-page'),
                MainAppContainer.route: (_) => const Text('home-page'),
                NodeManagementScreen.route: (_) => const Text('node-mgmt-page'),
              },
              home: SplashScreen(
                splashBloc: bloc,
                compositionFuture: compositionCompleter.future,
                initApp: (_) async => initCount += 1,
              ),
            ),
          );

          compositionCompleter.completeError(Exception('skip lottie'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(initCount, 1);
          expect(find.text('access-wallet-page'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'navigates to SyriusErrorWidget route when initialization throws',
      (WidgetTester tester) async {
        final Completer<LottieComposition> compositionCompleter =
            Completer<LottieComposition>();
        final SplashBloc bloc = SplashBloc(
          getWalletPath: () => null,
          getSelectedNode: () => null,
        );

        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              onGenerateRoute: (RouteSettings settings) {
                if (settings.name == SyriusErrorWidget.route) {
                  final CustomSyriusErrorWidgetArguments args =
                      settings.arguments! as CustomSyriusErrorWidgetArguments;
                  return MaterialPageRoute<void>(
                    builder: (_) => Text('error-route:${args.errorText}'),
                  );
                }
                return null;
              },
              home: SplashScreen(
                splashBloc: bloc,
                compositionFuture: compositionCompleter.future,
                initApp: (_) =>
                    Future<void>.error(Exception('startup failure')),
              ),
            ),
          );

          compositionCompleter.completeError(Exception('skip lottie'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('startup failure'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'prompts to retry when resetWalletFlow fails while clearing local data '
      'and succeeds on retry',
      (WidgetTester tester) async {
        int deleteWeb3Attempts = 0;
        final Completer<LottieComposition> compositionCompleter =
            Completer<LottieComposition>();
        final SplashBloc bloc = SplashBloc(
          setWalletInitIncomplete: () {},
          clearLastNotification: () async {},
          stopWebSocketClient: () {},
          clearAutoReceivePool: () {},
          stopHtlcSwapSync: () async {},
          closeHtlcSwapStorage: () async {},
          closeHive: () async {},
          deleteCacheBox: (_) async {},
          deleteWeb3Cache: () async {
            deleteWeb3Attempts += 1;
            if (deleteWeb3Attempts == 1) {
              throw StateError('keychain busy');
            }
          },
          deleteHtlcDatabase: () async {},
          deleteLegacyHtlcBoxes: () async {},
          deleteKeyStoreBox: () async {},
          closeAndDeleteWalletFile: () async {},
          getWalletPath: () => null,
          getSelectedNode: () => null,
        );

        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routes: <String, WidgetBuilder>{
                AccessWalletScreen.route: (_) =>
                    const Text('access-wallet-page'),
              },
              home: SplashScreen(
                resetWalletFlow: true,
                splashBloc: bloc,
                compositionFuture: compositionCompleter.future,
                initApp: (_) async {},
              ),
            ),
          );

          compositionCompleter.completeError(Exception('skip lottie'));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Wallet reset failed'), findsOneWidget);
          expect(find.textContaining('keychain busy'), findsOneWidget);

          await tester.tap(find.byKey(const Key('dialog_yes_button')));
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(deleteWeb3Attempts, 2);
          expect(find.text('access-wallet-page'), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );
  });

  group('DevelopmentInitializationScreen', () {
    testWidgets('navigates to AccessWalletScreen when wallet path is null', (
      WidgetTester tester,
    ) async {
      final SplashBloc bloc = SplashBloc(
        getWalletPath: () => null,
        getSelectedNode: () => null,
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: <String, WidgetBuilder>{
              AccessWalletScreen.route: (_) => const Text('dev-access-wallet'),
              MainAppContainer.route: (_) => const Text('dev-home'),
            },
            home: DevelopmentInitializationScreen(
              splashBloc: bloc,
              initApp: (_) async {},
            ),
          ),
        );

        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('dev-access-wallet'), findsOneWidget);
      } finally {
        await bloc.close();
      }
    });

    testWidgets('renders localized error text when initialization fails', (
      WidgetTester tester,
    ) async {
      final SplashBloc bloc = SplashBloc(
        getWalletPath: () => null,
        getSelectedNode: () => null,
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DevelopmentInitializationScreen(
                splashBloc: bloc,
                initApp: (_) =>
                    Future<void>.error(Exception('dev init failed')),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        expect(find.textContaining('Error:'), findsOneWidget);
        expect(find.textContaining('dev init failed'), findsOneWidget);
      } finally {
        await bloc.close();
      }
    });
  });
}
