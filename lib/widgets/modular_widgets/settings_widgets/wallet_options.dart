import 'dart:io';
import 'dart:typed_data';

import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/device_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WalletOptions extends StatefulWidget {
  final VoidCallback onResyncWalletPressed;

  const WalletOptions(this.onResyncWalletPressed, {Key? key}) : super(key: key);

  @override
  State<WalletOptions> createState() => _WalletOptionsState();
}

class _WalletOptionsState extends State<WalletOptions> {
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
        CustomExpandablePanel('Swap wallet', _getSwapWalletExpandedWidget()),
        CustomExpandablePanel('Provide feedback', _getProvideFeedbackWidget()),
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

  Widget _getSwapWalletExpandedWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This option will start the swap procedure',
          style: Theme.of(context).textTheme.subtitle2,
        ),
        kVerticalSpacing,
        Center(
          child: SettingsButton(
            onPressed: () {
              NavigationUtils.push(
                context,
                const SwapInfoScreen(),
              );
            },
            text: 'Swap wallet',
          ),
        ),
        kVerticalSpacing,
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

  Widget _getProvideFeedbackWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'This option will open a feedback utility window',
          style: Theme.of(context).textTheme.subtitle2,
        ),
        kVerticalSpacing,
        Center(
          child: SettingsButton(
            onPressed: () {
              BetterFeedback.of(context).show(
                (feedback) async {
                  try {
                    _shareFeedbackScreenshot(feedback.screenshot);
                  } catch (e) {
                    NotificationUtils.sendNotificationError(
                      e,
                      'Error while sharing feedback',
                    );
                  }
                },
              );
            },
            text: 'Provide feedback',
          ),
        ),
      ],
    );
  }

  void _shareFeedbackScreenshot(Uint8List feedbackScreenshot) async {
    final String screenshotFilePath =
        '${znnDefaultCacheDirectory.path}${Platform.pathSeparator}feedback_${DateTime.now().millisecondsSinceEpoch}.png';
    final File screenshotFile = File(screenshotFilePath);
    await screenshotFile.writeAsBytes(feedbackScreenshot);
    var screenshotFilePathList = <String>[];
    screenshotFilePathList.clear();
    screenshotFilePathList.add(screenshotFile.absolute.path);
    if (screenshotFilePath.isNotEmpty) {
      await Share.shareFiles(screenshotFilePathList,
          text:
              'Feedback provided at ${DateTime.now().millisecondsSinceEpoch} running on ${DeviceUtils.getDeviceInfo()} syrius wallet version ${DeviceUtils.getPackageInfo()}',
          subject: 'Syrius wallet feedback');
    } else {
      await Share.share(
        'Feedback provided at ${DateTime.now().millisecondsSinceEpoch} running on ${DeviceUtils.getDeviceInfo()} syrius wallet version ${DeviceUtils.getPackageInfo()}',
        subject: 'Syrius wallet feedback',
      );
    }
  }
}
