import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_display/settings_display.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_theme_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays appearance and theme preferences in the Settings tab.
class SettingsDisplayCard extends StatelessWidget {
  /// Creates a [SettingsDisplayCard].
  const SettingsDisplayCard({super.key, this._cubit});

  final SettingsDisplayCubit? _cubit;

  @override
  Widget build(BuildContext context) {
    final SettingsDisplayCubit? injected = _cubit;
    if (injected != null) {
      return BlocProvider<SettingsDisplayCubit>.value(
        value: injected,
        child: const _View(),
      );
    }

    return BlocProvider<SettingsDisplayCubit>(
      create: (_) => SettingsDisplayCubit(),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final GlobalKey<LoadingButtonState> _confirmThemeButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _confirmScaleButtonKey =
      GlobalKey<LoadingButtonState>();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      body: BlocConsumer<SettingsDisplayCubit, SettingsDisplayState>(
        listener: (BuildContext context, SettingsDisplayState state) {
          if (state.isSavingTheme) {
            _confirmThemeButtonKey.currentState?.animateForward();
          } else {
            _confirmThemeButtonKey.currentState?.animateReverse();
          }
          if (state.isSavingTextScaling) {
            _confirmScaleButtonKey.currentState?.animateForward();
          } else {
            _confirmScaleButtonKey.currentState?.animateReverse();
          }
        },
        builder: (BuildContext context, SettingsDisplayState state) {
          return ListView(
            shrinkWrap: true,
            children: <Widget>[
              CustomExpandablePanel(
                context.l10n.textScaling,
                _buildTextScalingPanel(context),
              ),
              CustomExpandablePanel(
                context.l10n.locale,
                _buildLocalePanel(context, state.selectedLocale),
              ),
              CustomExpandablePanel(
                context.l10n.theme,
                _buildThemePanel(context),
              ),
            ],
          );
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.display,
    description: context.l10n.walletAppearanceAndThemeSettings,
  );

  Widget _buildTextScalingPanel(BuildContext context) {
    final TextScalingNotifier textScalingNotifier = context
        .watch<TextScalingNotifier>();
    return Column(
      children: <Widget>[
        RadioGroup<TextScaling>(
          groupValue: textScalingNotifier.currentTextScaling,
          onChanged: (TextScaling? value) {
            if (value != null) {
              textScalingNotifier.changeTextScaling(value);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: TextScaling.values
                .map(
                  (TextScaling preset) => _buildRadioTile<TextScaling>(
                    context: context,
                    text: _textScalingLabel(context, preset),
                    value: preset,
                  ),
                )
                .toList(),
          ),
        ),
        _buildConfirmScaleButton(context),
      ],
    );
  }

  Widget _buildLocalePanel(BuildContext context, LocaleType selectedLocale) {
    return RadioGroup<LocaleType>(
      groupValue: selectedLocale,
      onChanged: (LocaleType? value) {
        if (value != null) {
          context.read<SettingsDisplayCubit>().selectLocale(value);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: LocaleType.values
            .map(
              (LocaleType locale) => _buildRadioTile<LocaleType>(
                context: context,
                text: _localeLabel(context, locale),
                value: locale,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildThemePanel(BuildContext context) {
    final AppThemeNotifier themeNotifier = context.watch<AppThemeNotifier>();
    return Column(
      children: <Widget>[
        RadioGroup<ThemeMode>(
          groupValue: themeNotifier.currentThemeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeNotifier.changeThemeMode(value);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ThemeMode.values
                .map(
                  (ThemeMode mode) => _buildRadioTile<ThemeMode>(
                    context: context,
                    text: _themeModeLabel(context, mode),
                    value: mode,
                  ),
                )
                .toList(),
          ),
        ),
        _buildConfirmThemeButton(context),
      ],
    );
  }

  Widget _buildRadioTile<T>({
    required BuildContext context,
    required String text,
    required T value,
  }) {
    return Row(
      children: <Widget>[
        Radio<T>(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: value,
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmThemeButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: LoadingButton.settings(
            text: context.l10n.confirmTheme,
            onPressed: () {
              final ThemeMode? currentThemeMode = context
                  .read<AppThemeNotifier>()
                  .currentThemeMode;
              final String modeLabel = currentThemeMode != null
                  ? _themeModeLabel(context, currentThemeMode)
                  : '';
              unawaited(
                context.read<SettingsDisplayCubit>().confirmThemeMode(
                  themeMode: currentThemeMode,
                  notificationTitle: context.l10n.themeModeChanged,
                  notificationDetails: context.l10n.themeModeChangedDetails(
                    modeLabel,
                  ),
                  errorTitle: context.l10n.themeModeChangeFailed,
                ),
              );
            },
            key: _confirmThemeButtonKey,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmScaleButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: LoadingButton.settings(
            text: context.l10n.confirmScale,
            onPressed: () {
              final TextScaling? currentTextScaling = context
                  .read<TextScalingNotifier>()
                  .currentTextScaling;
              final String scaleLabel = currentTextScaling != null
                  ? _textScalingLabel(context, currentTextScaling)
                  : '';
              unawaited(
                context.read<SettingsDisplayCubit>().confirmTextScaling(
                  textScaling: currentTextScaling,
                  notificationTitle: context.l10n.textScaleChanged,
                  notificationDetails: context.l10n.textScaleChangedDetails(
                    scaleLabel,
                  ),
                  errorTitle: context.l10n.textScaleChangeFailed,
                ),
              );
            },
            key: _confirmScaleButtonKey,
          ),
        ),
      ],
    );
  }

  String _textScalingLabel(BuildContext context, TextScaling preset) {
    return switch (preset) {
      TextScaling.system => context.l10n.system,
      TextScaling.small => context.l10n.small,
      TextScaling.normal => context.l10n.normal,
      TextScaling.large => context.l10n.large,
      TextScaling.huge => context.l10n.huge,
    };
  }

  String _localeLabel(BuildContext context, LocaleType locale) {
    return switch (locale) {
      LocaleType.english => context.l10n.english,
    };
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => context.l10n.system,
      ThemeMode.light => context.l10n.light,
      ThemeMode.dark => context.l10n.dark,
    };
  }
}
