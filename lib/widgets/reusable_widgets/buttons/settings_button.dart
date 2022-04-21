import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/outlined_button.dart';

class SettingsButton extends MyOutlinedButton {
  const SettingsButton({
    required VoidCallback? onPressed,
    required String text,
    Key? key,
  }) : super(
          key: key,
          onPressed: onPressed,
          text: text,
          textStyle: kText2TextStyle,
          minimumSize: kSettingsButtonMinSize,
        );
}
