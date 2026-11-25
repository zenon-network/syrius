import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/reset_wallet/reset_wallet.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';

void main() {
  group('ResetWalletCubit', () {
    blocTest<ResetWalletCubit, ResetWalletState>(
      'closes embedded node, dismisses notification, and emits readyToNavigate',
      build: () => ResetWalletCubit(
        closeEmbeddedNode: () async {},
        dismissLastNotification: () {},
      ),
      act: (ResetWalletCubit cubit) => cubit.confirmReset(),
      expect: () => const <ResetWalletState>[
        ResetWalletInProgress(),
        ResetWalletReadyToNavigate(),
      ],
    );

    blocTest<ResetWalletCubit, ResetWalletState>(
      'still emits readyToNavigate if closing embedded node throws',
      build: () => ResetWalletCubit(
        closeEmbeddedNode: () async => throw StateError('node hung'),
        dismissLastNotification: () {},
      ),
      act: (ResetWalletCubit cubit) => cubit.confirmReset(),
      expect: () => const <ResetWalletState>[
        ResetWalletInProgress(),
        ResetWalletReadyToNavigate(),
      ],
    );
  });

  group('ResetWalletScreen', () {
    testWidgets('tapping Reset triggers cleanup and splash navigation', (
      WidgetTester tester,
    ) async {
      bool closedEmbedded = false;
      bool dismissedNotification = false;
      bool navigatedToResetSplash = false;

      final ResetWalletCubit cubit = ResetWalletCubit(
        closeEmbeddedNode: () async {
          closedEmbedded = true;
        },
        dismissLastNotification: () {
          dismissedNotification = true;
        },
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResetWalletScreen(
            cubit: cubit,
            onNavigateToResetSplash: () {
              navigatedToResetSplash = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(closedEmbedded, isTrue);
      expect(dismissedNotification, isTrue);
      expect(navigatedToResetSplash, isTrue);
    });
  });
}
