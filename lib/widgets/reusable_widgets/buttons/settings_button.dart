import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SettingsButton extends MyOutlinedButton {
  const SettingsButton({
    required super.onPressed,
    required String super.text,
    super.key,
  }) : super(
          textStyle: kBodyMediumTextStyle,
          minimumSize: kSettingsButtonMinSize,
        );
}
