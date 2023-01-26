import 'dart:io';

import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class WalletOptions extends StatefulWidget {
  final VoidCallback onResyncWalletPressed;

  const WalletOptions(this.onResyncWalletPressed, {Key? key}) : super(key: key);

  @override
  State<WalletOptions> createState() => _WalletOptionsState();
}

class _WalletOptionsState extends State<WalletOptions> {
  bool? _launchAtStartup;
  bool? _enableDesktopNotifications;

  @override
  void initState() {
    super.initState();
    _launchAtStartup = sharedPrefsService!.get(
      kLaunchAtStartupKey,
      defaultValue: kLaunchAtStartupDefaultValue,
    );
    _enableDesktopNotifications = sharedPrefsService!.get(
      kEnableDesktopNotificationsKey,
      defaultValue: kEnableDesktopNotificationsDefaultValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Wallet Options',
      description: 'Other wallet options',
      childBuilder: () => _getWidgetBody(),
    );
  }

  Widget _getWidgetBody() {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel('Delete cache', _getDeleteCacheExpandedWidget()),
        CustomExpandablePanel('Reset wallet', _getResetWalletExpandedWidget()),
        CustomExpandablePanel('Preferences', _getPreferencesExpandedWidget()),
      ],
    );
  }

  Column _getResetWalletExpandedWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'This option will erase the wallet files. Make sure you have a '
          'backup first',
          style: Theme.of(context).textTheme.subtitle2,
        ),
        kVerticalSpacing,
        Center(
          child: SettingsButton(
            onPressed: () => NavigationUtils.push(
              context,
              const ResetWalletScreen(),
            ),
            text: 'Reset wallet',
          ),
        ),
      ],
    );
  }

  Widget _getDeleteCacheExpandedWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'This option will delete the wallet cache and close the application',
          style: Theme.of(context).textTheme.subtitle2,
        ),
        kVerticalSpacing,
        Center(
          child: SettingsButton(
            onPressed: () {
              NavigationUtils.pushReplacement(
                context,
                const SplashScreen(
                  deleteCacheFlow: true,
                ),
              );
            },
            text: 'Delete cache',
          ),
        ),
      ],
    );
  }

  Widget _getPreferencesExpandedWidget() {
    return Column(
      children: [
        _getLaunchAtStartupWidget(),
        _getEnableDesktopNotifications(),
      ],
    );
  }

  Widget _getLaunchAtStartupWidget() {
    return Row(
      children: [
        Text(
          'Launch at startup: ',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        SyriusCheckbox(
          onChanged: (value) {
            setState(() {
              _launchAtStartup = value;
              _changeLaunchAtStartupStatus(value ?? false);
            });
          },
          value: _launchAtStartup,
          context: context,
        ),
      ],
    );
  }

  Future<void> _setupLaunchAtStartup() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  Future<void> _changeLaunchAtStartupStatus(bool enabled) async {
    try {
      await _setupLaunchAtStartup();
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      await _saveLaunchAtStartupValueToCache(enabled);
      _sendLaunchAtStartupStatusNotification(enabled);
    } on Exception catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Something went wrong while change launch at startup status',
      );
    }
  }

  Future<void> _saveLaunchAtStartupValueToCache(bool enabled) async {
    await sharedPrefsService!.put(
      kLaunchAtStartupKey,
      enabled,
    );
  }

  void _sendLaunchAtStartupStatusNotification(bool enabled) {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Launch at startup was ${enabled ? 'enabled' : 'disabled'}',
            details:
                'Launch at startup preference was ${enabled ? 'enabled' : 'disabled'}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            type: NotificationType.paymentSent,
          ),
        );
  }

  Widget _getEnableDesktopNotifications() {
    return Row(
      children: [
        Text(
          'Enable desktop notifications: ',
          style: Theme.of(context).textTheme.subtitle1,
        ),
        SyriusCheckbox(
          onChanged: (value) {
            setState(() {
              _enableDesktopNotifications = value;
              _changeEnableDesktopNotificationsStatus(value ?? false);
            });
          },
          value: _enableDesktopNotifications,
          context: context,
        ),
      ],
    );
  }

  Future<void> _changeEnableDesktopNotificationsStatus(bool enabled) async {
    try {
      await sharedPrefsService!.put(kEnableDesktopNotificationsKey, enabled);
      _sendEnabledDesktopNotificationsStatusNotification(enabled);
    } on Exception catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Something went wrong while changing the preferences of desktop notifications',
      );
    }
  }

  void _sendEnabledDesktopNotificationsStatusNotification(bool enabled) {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title:
                'Desktop notifications have been ${enabled ? 'enabled' : 'disabled'}',
            details:
                'You changed the desktop notifications preference to ${enabled ? 'enabled' : 'disabled'}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            type: NotificationType.paymentSent,
          ),
        );
  }
}
