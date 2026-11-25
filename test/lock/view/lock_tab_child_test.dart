import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockWalletFile extends Mock implements WalletFile {}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('LockTabChild', () {
    testWidgets(
      'renders localized copy, preserves integration keys, shows initializing '
      'state, and clears password on unlock success',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final _MockWalletFile walletFile = _MockWalletFile();
        final Completer<void> initCompleter = Completer<void>();
        bool initCallbackCalled = false;

        final WalletUnlockBloc bloc = WalletUnlockBloc(
          afterUnlockCallback: (_) async {},
          afterInitCallback: () => initCallbackCalled = true,
          decryptWallet: (_, _) async => walletFile,
          initWalletAfterDecryption: (_) => initCompleter.future,
          getWalletPath: () => '/tmp/wallet',
          setWalletFile: (_) {},
          isWalletInitCompleted: () => false,
          getNumFailedAttempts: () => 0,
          saveNumFailedAttempts: (_) async {},
          getAutoEraseWalletLimit: () => 3,
          onFetchBalances: () {},
          sendErrorNotification: (_, _) async {},
        );

        try {
          await tester.pumpWidget(
            _buildTestApp(LockTabChild((_) async {}, () {}, unlockBloc: bloc)),
          );

          expect(find.text('Welcome Back'), findsOneWidget);
          expect(
            find.text('Enter the password to access the wallet'),
            findsOneWidget,
          );
          expect(find.text('3 attempts left'), findsOneWidget);
          expect(
            find.byKey(const Key('wallet_password_field')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('wallet_unlock_button')), findsOneWidget);

          await tester.enterText(
            find.descendant(
              of: find.byKey(const Key('wallet_password_field')),
              matching: find.byType(TextFormField),
            ),
            'StrongPass1!',
          );
          await tester.tap(find.byKey(const Key('wallet_unlock_button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text('Initializing wallet, please wait'), findsOneWidget);

          initCompleter.complete();
          await tester.pumpAndSettle();

          expect(initCallbackCalled, isTrue);
          final TextFormField field = tester.widget<TextFormField>(
            find.descendant(
              of: find.byKey(const Key('wallet_password_field')),
              matching: find.byType(TextFormField),
            ),
          );
          expect(field.controller!.text, isEmpty);
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'updates remaining attempts to last-attempt warning on wrong password',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        int failedAttempts = 1;
        final WalletUnlockBloc bloc = WalletUnlockBloc(
          afterUnlockCallback: (_) async {},
          afterInitCallback: () {},
          decryptWallet: (_, _) =>
              Future<WalletFile>.error(IncorrectPasswordException()),
          initWalletAfterDecryption: (_) async {},
          getWalletPath: () => '/tmp/wallet',
          setWalletFile: (_) {},
          isWalletInitCompleted: () => true,
          getNumFailedAttempts: () => failedAttempts,
          saveNumFailedAttempts: (int count) async => failedAttempts = count,
          getAutoEraseWalletLimit: () => 3,
          onFetchBalances: () {},
          sendErrorNotification: (_, _) async {},
        );

        try {
          await tester.pumpWidget(
            _buildTestApp(LockTabChild((_) async {}, () {}, unlockBloc: bloc)),
          );

          expect(find.text('2 attempts left'), findsOneWidget);

          await tester.enterText(
            find.descendant(
              of: find.byKey(const Key('wallet_password_field')),
              matching: find.byType(TextFormField),
            ),
            'wrong',
          );
          await tester.tap(find.byKey(const Key('wallet_unlock_button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(
            find.text(
              'Last attempt. The wallet will be reset if this attempt fails',
            ),
            findsOneWidget,
          );
        } finally {
          await bloc.close();
        }
      },
    );

    testWidgets(
      'navigates to SplashScreen(resetWalletFlow: true) on auto-erase',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        int failedAttempts = 2;
        final WalletUnlockBloc bloc = WalletUnlockBloc(
          afterUnlockCallback: (_) async {},
          afterInitCallback: () {},
          decryptWallet: (_, _) =>
              Future<WalletFile>.error(IncorrectPasswordException()),
          initWalletAfterDecryption: (_) async {},
          getWalletPath: () => '/tmp/wallet',
          setWalletFile: (_) {},
          isWalletInitCompleted: () => true,
          getNumFailedAttempts: () => failedAttempts,
          saveNumFailedAttempts: (int count) async => failedAttempts = count,
          getAutoEraseWalletLimit: () => 3,
          onFetchBalances: () {},
          sendErrorNotification: (_, _) async {},
        );

        try {
          await tester.pumpWidget(
            _buildTestApp(LockTabChild((_) async {}, () {}, unlockBloc: bloc)),
          );

          await tester.enterText(
            find.descendant(
              of: find.byKey(const Key('wallet_password_field')),
              matching: find.byType(TextFormField),
            ),
            'wrong-final',
          );
          await tester.tap(find.byKey(const Key('wallet_unlock_button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.byType(SplashScreen), findsOneWidget);
        } finally {
          await bloc.close();
        }
      },
    );
  });
}
