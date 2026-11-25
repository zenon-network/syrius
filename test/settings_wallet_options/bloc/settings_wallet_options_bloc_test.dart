import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_wallet_options/settings_wallet_options.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class MockSharedPrefsService extends Mock implements SharedPrefsService {}

void main() {
  group('SettingsWalletOptionsBloc', () {
    late MockSharedPrefsService prefs;
    late List<WalletNotification> notifications;
    late List<String> errors;
    late int clipboardToggles;
    late int autoReceiveTriggers;
    late int poolClears;
    late bool? configuredLaunchAtStartup;

    setUp(() {
      prefs = MockSharedPrefsService();
      notifications = <WalletNotification>[];
      errors = <String>[];
      clipboardToggles = 0;
      autoReceiveTriggers = 0;
      poolClears = 0;
      configuredLaunchAtStartup = null;

      when(
        () => prefs.get(
          kLaunchAtStartupKey,
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(false);
      when(
        () => prefs.get(
          kEnableDesktopNotificationsKey,
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(false);
      when(
        () => prefs.get(
          kEnableClipboardWatcherKey,
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(false);
      when(
        () => prefs.get(
          kAutoReceiveKey,
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(true);
      when(() => prefs.put(any(), any<dynamic>())).thenAnswer((_) async {});
    });

    SettingsWalletOptionsBloc buildBloc({
      bool isMacOs = false,
      Future<bool> Function()? requestPermissions,
      Future<void> Function({required bool enabled})? configureLaunchAtStartup,
      Future<void> Function(WalletNotification notification)? addNotification,
    }) => SettingsWalletOptionsBloc(
      prefsService: prefs,
      isMacOs: isMacOs,
      requestMacOsNotificationPermissions: requestPermissions,
      configureLaunchAtStartup:
          configureLaunchAtStartup ??
          ({required bool enabled}) async {
            configuredLaunchAtStartup = enabled;
          },
      toggleClipboardWatcher: () {
        clipboardToggles++;
      },
      triggerAutoReceive: () async {
        autoReceiveTriggers++;
      },
      clearAutoReceivePool: () {
        poolClears++;
      },
      addNotification:
          addNotification ??
          (WalletNotification notification) async {
            notifications.add(notification);
          },
      reportError: (Object error, String title) async {
        errors.add(title);
      },
    );

    blocTest<SettingsWalletOptionsBloc, SettingsWalletOptionsState>(
      'toggles launch at startup and persists preference',
      build: buildBloc,
      act: (SettingsWalletOptionsBloc bloc) => bloc.add(
        const SettingsWalletOptionsLaunchAtStartupToggled(
          enabled: true,
          notificationTitle: 'Launch startup enabled',
          notificationDetails: 'Enabled',
          errorTitle: 'Error',
        ),
      ),
      expect: () => const <SettingsWalletOptionsState>[
        SettingsWalletOptionsState(
          launchAtStartup: true,
          enableDesktopNotifications: false,
          enableClipboardWatcher: false,
          autoReceive: true,
        ),
      ],
      verify: (_) {
        expect(configuredLaunchAtStartup, isTrue);
        verify(() => prefs.put(kLaunchAtStartupKey, true)).called(1);
        expect(notifications, hasLength(1));
      },
    );

    blocTest<SettingsWalletOptionsBloc, SettingsWalletOptionsState>(
      'reverts launch at startup when OS configuration throws',
      build: () => buildBloc(
        configureLaunchAtStartup: ({required bool enabled}) async =>
            throw StateError('denied'),
      ),
      act: (SettingsWalletOptionsBloc bloc) => bloc.add(
        const SettingsWalletOptionsLaunchAtStartupToggled(
          enabled: true,
          notificationTitle: 'Launch startup enabled',
          notificationDetails: 'Enabled',
          errorTitle: 'Launch error',
        ),
      ),
      expect: () => const <SettingsWalletOptionsState>[
        SettingsWalletOptionsState(
          launchAtStartup: true,
          enableDesktopNotifications: false,
          enableClipboardWatcher: false,
          autoReceive: true,
        ),
        SettingsWalletOptionsState(
          launchAtStartup: false,
          enableDesktopNotifications: false,
          enableClipboardWatcher: false,
          autoReceive: true,
        ),
      ],
      verify: (_) {
        expect(errors, <String>['Launch error']);
      },
    );

    blocTest<SettingsWalletOptionsBloc, SettingsWalletOptionsState>(
      'does not enable desktop notifications on macOS when permission denied',
      build: () =>
          buildBloc(isMacOs: true, requestPermissions: () async => false),
      act: (SettingsWalletOptionsBloc bloc) => bloc.add(
        const SettingsWalletOptionsDesktopNotificationsToggled(
          enabled: true,
          notificationTitle: 'Desktop enabled',
          notificationDetails: 'Enabled',
          errorTitle: 'Error',
        ),
      ),
      expect: () => const <SettingsWalletOptionsState>[],
      verify: (_) {
        verifyNever(() => prefs.put(kEnableDesktopNotificationsKey, true));
      },
    );

    blocTest<SettingsWalletOptionsBloc, SettingsWalletOptionsState>(
      'toggles clipboard watcher and updates watcher status',
      build: buildBloc,
      act: (SettingsWalletOptionsBloc bloc) => bloc.add(
        const SettingsWalletOptionsClipboardWatcherToggled(
          enabled: true,
          notificationTitle: 'Watcher enabled',
          notificationDetails: 'Enabled',
          errorTitle: 'Error',
        ),
      ),
      expect: () => const <SettingsWalletOptionsState>[
        SettingsWalletOptionsState(
          launchAtStartup: false,
          enableDesktopNotifications: false,
          enableClipboardWatcher: true,
          autoReceive: true,
        ),
      ],
      verify: (_) {
        expect(clipboardToggles, 1);
        verify(() => prefs.put(kEnableClipboardWatcherKey, true)).called(1);
      },
    );

    blocTest<SettingsWalletOptionsBloc, SettingsWalletOptionsState>(
      'toggles auto-receive off clears pool and on triggers worker',
      build: buildBloc,
      act: (SettingsWalletOptionsBloc bloc) {
        bloc
          ..add(
            const SettingsWalletOptionsAutoReceiveToggled(
              enabled: false,
              notificationTitle: 'Disabled',
              notificationDetails: 'Disabled',
              errorTitle: 'Error',
            ),
          )
          ..add(
            const SettingsWalletOptionsAutoReceiveToggled(
              enabled: true,
              notificationTitle: 'Enabled',
              notificationDetails: 'Enabled',
              errorTitle: 'Error',
            ),
          );
      },
      expect: () => const <SettingsWalletOptionsState>[
        SettingsWalletOptionsState(
          launchAtStartup: false,
          enableDesktopNotifications: false,
          enableClipboardWatcher: false,
          autoReceive: false,
        ),
        SettingsWalletOptionsState(
          launchAtStartup: false,
          enableDesktopNotifications: false,
          enableClipboardWatcher: false,
          autoReceive: true,
        ),
      ],
      verify: (_) {
        expect(poolClears, 1);
        expect(autoReceiveTriggers, 1);
      },
    );

    blocTest<SettingsWalletOptionsBloc, SettingsWalletOptionsState>(
      'keeps persisted toggle enabled when post-save notification throws',
      build: () => buildBloc(
        addNotification: (_) async => throw StateError('notification failed'),
      ),
      act: (SettingsWalletOptionsBloc bloc) => bloc.add(
        const SettingsWalletOptionsDesktopNotificationsToggled(
          enabled: true,
          notificationTitle: 'Desktop enabled',
          notificationDetails: 'Enabled',
          errorTitle: 'Notification error',
        ),
      ),
      expect: () => const <SettingsWalletOptionsState>[
        SettingsWalletOptionsState(
          launchAtStartup: false,
          enableDesktopNotifications: true,
          enableClipboardWatcher: false,
          autoReceive: true,
        ),
      ],
      verify: (_) {
        verify(() => prefs.put(kEnableDesktopNotificationsKey, true)).called(1);
        expect(errors, <String>['Notification error']);
      },
    );
  });
}
