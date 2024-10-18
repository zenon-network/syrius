import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_theme_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

enum TextScaling {
  system,
  small,
  normal,
  large,
  huge,
}

enum LocaleType {
  english,
}

class DisplayWidget extends StatefulWidget {
  const DisplayWidget({super.key});

  @override
  State<DisplayWidget> createState() => _DisplayWidget();
}

class _DisplayWidget extends State<DisplayWidget> {
  LocaleType? _selectedLocaleType = LocaleType.english;

  final GlobalKey<LoadingButtonState> _confirmThemeButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _confirmScaleButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Display',
      description: 'Wallet appearance and theme settings',
      childBuilder: _getWidgetBody,
    );
  }

  Widget _getWidgetBody() {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel('Text scaling', _getTextScalingExpandableChild()),
        CustomExpandablePanel('Locale', _getLocaleExpandableChild()),
        CustomExpandablePanel('Theme', _getThemeExpandableChild()),
      ],
    );
  }

  Widget _getTextScalingExpandableChild() {
    return Column(
      children: [
        _getTextScalingTiles(),
        _getConfirmScaleButton(),
      ],
    );
  }

  Column _getTextScalingTiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: TextScaling.values
          .map(
            (e) => _getListTile<TextScaling>(
              FormatUtils.extractNameFromEnum<TextScaling>(e),
              e,
            ),
          )
          .toList(),
    );
  }

  Widget _getListTile<T>(String text, T value) {
    return Row(
      children: [
        Radio<T>(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: value,
          groupValue: value is TextScaling
              ? Provider.of<TextScalingNotifier>(
                  context,
                  listen: false,
                ).currentTextScaling as T
              : value is LocaleType
                  ? _selectedLocaleType as T?
                  : Provider.of<AppThemeNotifier>(
                      context,
                      listen: false,
                    ).currentThemeMode as T?,
          onChanged: (T? value) {
            setState(() {
              if (value is TextScaling) {
                Provider.of<TextScalingNotifier>(
                  context,
                  listen: false,
                ).changeTextScaling(value);
              }
              if (value is LocaleType) {
                _selectedLocaleType = value;
              }
              if (value is ThemeMode) {
                Provider.of<AppThemeNotifier>(context, listen: false)
                    .changeThemeMode(value);
              }
            });
          },
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 10,
                ),
          ),
        ),
      ],
    );
  }

  Widget _getLocaleExpandableChild() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: LocaleType.values
          .map(
            (e) => _getListTile<LocaleType>(
              FormatUtils.extractNameFromEnum<LocaleType>(e),
              e,
            ),
          )
          .toList(),
    );
  }

  Widget _getThemeExpandableChild() {
    return Column(
      children: [
        _getThemeModeTiles(),
        _getConfirmThemeButton(),
      ],
    );
  }

  Column _getThemeModeTiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ThemeMode.values
          .map(
            (e) => _getListTile<ThemeMode>(
              FormatUtils.extractNameFromEnum<ThemeMode>(e),
              e,
            ),
          )
          .toList(),
    );
  }

  Widget _getConfirmThemeButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: LoadingButton.settings(
            text: 'Confirm theme',
            onPressed: _onConfirmThemeButtonPressed,
            key: _confirmThemeButtonKey,
          ),
        ),
      ],
    );
  }

  Future<void> _onConfirmThemeButtonPressed() async {
    try {
      _confirmThemeButtonKey.currentState!.animateForward();
      final currentThemeMode = Provider.of<AppThemeNotifier>(
        context,
        listen: false,
      ).currentThemeMode;
      sharedPrefsService!.put(
        kThemeModeKey,
        currentThemeMode.toString(),
      );
      await sl.get<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Theme mode changed',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Theme mode successfully changed to '
                  '${FormatUtils.extractNameFromEnum<ThemeMode?>(
                Provider.of<AppThemeNotifier>(
                  context,
                  listen: false,
                ).currentThemeMode,
              )}',
              type: NotificationType.paymentSent,
            ),
          );
    } catch (e) {
      await NotificationUtils.sendNotificationError(e, 'Theme mode change failed');
    } finally {
      _confirmThemeButtonKey.currentState!.animateReverse();
    }
  }

  Widget _getConfirmScaleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: LoadingButton.settings(
            text: 'Confirm scale',
            onPressed: _onConfirmScaleButtonPressed,
            key: _confirmScaleButtonKey,
          ),
        ),
      ],
    );
  }

  Future<void> _onConfirmScaleButtonPressed() async {
    try {
      _confirmScaleButtonKey.currentState!.animateForward();

      final currentTextScaling = Provider.of<TextScalingNotifier>(
        context,
        listen: false,
      ).currentTextScaling;

      sharedPrefsService!.put(
        kTextScalingKey,
        currentTextScaling.toString(),
      );

      await sl.get<NotificationsBloc>().addNotification(
            WalletNotification(
                title: 'Text scale changed',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details: 'Text scale successfully changed to '
                    '${FormatUtils.extractNameFromEnum<TextScaling?>(currentTextScaling)}',
                type: NotificationType.paymentSent,),
          );
    } catch (e) {
      await NotificationUtils.sendNotificationError(e, 'Text scale change failed');
    } finally {
      _confirmScaleButtonKey.currentState!.animateReverse();
    }
  }
}
