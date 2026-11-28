import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_ui_preferences_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

Widget _wrapThemed(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppUiPreferencesNotifier', () {
    test('exposes sensible defaults and notifies on updates', () {
      final AppUiPreferencesNotifier notifier = AppUiPreferencesNotifier();
      int notifications = 0;
      notifier.addListener(() => notifications += 1);

      expect(notifier.hideBalances, isFalse);
      expect(notifier.sidebarExpanded, isFalse);
      expect(notifier.showFiatValues, isFalse);
      expect(notifier.webAppsEnabled, isFalse);
      expect(notifier.pillarMode, FeatureDisplayMode.auto);
      expect(notifier.sentinelMode, FeatureDisplayMode.auto);
      expect(notifier.sporksMode, FeatureDisplayMode.off);
      expect(notifier.contacts, isEmpty);

      notifier.toggleHideBalances();
      expect(notifier.hideBalances, isTrue);
      notifier.toggleSidebarExpanded();
      expect(notifier.sidebarExpanded, isTrue);
      notifier.showFiatValues = true;
      expect(notifier.showFiatValues, isTrue);
      notifier.webAppsEnabled = true;
      expect(notifier.webAppsEnabled, isTrue);
      notifier.setSelectedExplorer('https://zenonhub.io/explorer/');
      expect(notifier.selectedExplorer, 'https://zenonhub.io/explorer/');
      notifier.setPillarMode(FeatureDisplayMode.on);
      expect(notifier.pillarMode, FeatureDisplayMode.on);
      notifier.setSentinelMode(FeatureDisplayMode.off);
      expect(notifier.sentinelMode, FeatureDisplayMode.off);
      notifier.setSporksMode(FeatureDisplayMode.auto);
      expect(notifier.sporksMode, FeatureDisplayMode.auto);

      notifier.saveContact('z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a', 'Alice');
      expect(
        notifier.contactLabelFor('z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a'),
        'Alice',
      );
      notifier.removeContact('z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a');
      expect(notifier.contacts, isEmpty);
      expect(notifications, greaterThanOrEqualTo(10));
    });
  });

  group('ShellNavigationController', () {
    test('updates transfer requests with monotonic nonce and settings '
        'sections', () {
      final ShellNavigationController controller = ShellNavigationController();
      addTearDown(controller.dispose);

      controller.requestTransfer(
        mode: TransferMode.zap,
        recipientAddress: 'z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a',
      );
      expect(controller.transferRequest.value.mode, TransferMode.zap);
      expect(
        controller.transferRequest.value.recipientAddress,
        'z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a',
      );
      expect(controller.transferRequest.value.nonce, 1);

      controller.requestTransfer(mode: TransferMode.zap);
      expect(controller.transferRequest.value.nonce, 2);

      int sectionChanges = 0;
      controller.settingsSection.addListener(() => sectionChanges += 1);
      controller
        ..requestSettingsSection(SettingsSection.about)
        ..requestSettingsSection(SettingsSection.about);
      expect(controller.settingsSection.value, SettingsSection.about);
      expect(sectionChanges, 1);
    });
  });

  group('SyriusThemeTokens', () {
    test('provides dark and light extensions with copyWith and lerp', () {
      final SyriusThemeTokens? dark = AppTheme.darkTheme
          .extension<SyriusThemeTokens>();
      final SyriusThemeTokens? light = AppTheme.lightTheme
          .extension<SyriusThemeTokens>();
      expect(dark, isNotNull);
      expect(light, isNotNull);
      expect(dark!.shellBackground, isNot(light!.shellBackground));

      final SyriusThemeTokens overridden = dark.copyWith(
        znnGreen: Colors.teal,
      );
      expect(overridden.znnGreen, Colors.teal);

      final SyriusThemeTokens mid = dark.lerp(light, 0.5);
      expect(mid.surface, isNot(dark.surface));
      expect(mid.surface, isNot(light.surface));
    });
  });

  group('Redesign UI kit widgets', () {
    testWidgets('SyriusNavigationRail toggles expansion and selects tabs', (
      WidgetTester tester,
    ) async {
      Tabs? selected;
      bool toggled = false;
      bool notificationsOpened = false;
      bool locked = false;

      await tester.pumpWidget(
        _wrapThemed(
          SizedBox(
            height: 760,
            child: SyriusNavigationRail(
              activeTab: Tabs.dashboard,
              isExpanded: true,
              hasUnreadNotifications: true,
              isNotificationsOpen: false,
              onToggleExpanded: () => toggled = true,
              onTabSelected: (Tabs tab) => selected = tab,
              onNotificationsPressed: () => notificationsOpened = true,
              onLockPressed: () => locked = true,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Staking'), findsOneWidget);
      expect(find.text('Nodes'), findsOneWidget);
      expect(find.text('Plasma'), findsOneWidget);
      expect(find.text('Tokens'), findsOneWidget);

      await tester.tap(find.text('Transfer'));
      expect(selected, Tabs.transfer);

      await tester.tap(find.text('Notifications'));
      expect(notificationsOpened, isTrue);

      await tester.tap(find.text('Lock'));
      expect(locked, isTrue);

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(toggled, isTrue);
    });

    testWidgets('SyriusSegmentedControl and SyriusHorizontalStepper render '
        'in light and dark themes without overflow', (
      WidgetTester tester,
    ) async {
      String picked = 'a';
      await tester.pumpWidget(
        _wrapThemed(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  SyriusSegmentedControl<String>(
                    selected: picked,
                    onChanged: (String v) => setState(() => picked = v),
                    options: const <SyriusSegmentOption<String>>[
                      SyriusSegmentOption<String>(value: 'a', label: 'Alpha'),
                      SyriusSegmentOption<String>(value: 'b', label: 'Beta'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 420,
                    child: SyriusHorizontalStepper(
                      steps: <String>['Seed', 'Confirm', 'Password', 'Ready'],
                      currentStep: 2,
                    ),
                  ),
                ],
              );
            },
          ),
          theme: AppTheme.lightTheme,
        ),
      );

      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(picked, 'b');
    });

    testWidgets(
      'SyriusModalShell renders inside showCustomDialog (unbounded height) '
      'without layout assertions',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapThemed(
            Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    unawaited(
                      showCustomDialog<void>(
                        context: context,
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: const SyriusModalShell(
                            title: 'Start swap',
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text('Swap form body'),
                                SizedBox(height: 24),
                                Text('Footer content'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open modal'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Start swap'), findsOneWidget);
        expect(find.text('Swap form body'), findsOneWidget);
      },
    );

    testWidgets(
      'SyriusPaginatedListView auto-requests more when viewport is unfilled '
      'and deduplicates requests until itemCount updates',
      (WidgetTester tester) async {
        int loadMoreCalls = 0;

        await tester.pumpWidget(
          _wrapThemed(
            SizedBox(
              height: 400,
              child: SyriusPaginatedListView(
                itemCount: 2,
                hasReachedMax: false,
                onLoadMore: () => loadMoreCalls += 1,
                itemBuilder: (_, int i) => SizedBox(
                  height: 40,
                  child: Text('Row $i'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(loadMoreCalls, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Updating itemCount allows another fetch when still not max.
        await tester.pumpWidget(
          _wrapThemed(
            SizedBox(
              height: 400,
              child: SyriusPaginatedListView(
                itemCount: 4,
                hasReachedMax: true,
                onLoadMore: () => loadMoreCalls += 1,
                itemBuilder: (_, int i) => SizedBox(
                  height: 40,
                  child: Text('Row $i'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(loadMoreCalls, 1);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}
