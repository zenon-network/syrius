import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SendPaymentButton extends LoadingButton {
  const SendPaymentButton({
    required VoidCallback? onPressed,
    required Key key,
    String text = 'Send',
    Color? outlineColor,
    Size minimumSize = const Size(100.0, 40.0),
  }) : super(
          onPressed: onPressed,
          text: text,
          key: key,
          minimumSize: minimumSize,
          outlineColor: outlineColor,
          paddingAroundChild: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
        );

  factory SendPaymentButton.error({
    required VoidCallback? onPressed,
    required Key key,
    String text = 'Retry',
    Size minimumSize = const Size(150.0, 40.0),
  }) =>
      SendPaymentButton(
        onPressed: onPressed,
        text: 'Retry',
        outlineColor: AppColors.errorColor,
        minimumSize: minimumSize,
        key: key,
      );
}
