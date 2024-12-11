import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SendPaymentButton extends LoadingButton {
  const SendPaymentButton({
    required super.onPressed,
    required super.key,
    String super.text = 'Send',
    super.outlineColor,
    super.minimumSize = const Size(100, 40),
  }) : super(
          paddingAroundChild: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
        );

  factory SendPaymentButton.error({
    required VoidCallback? onPressed,
    required Key key,
    Size minimumSize = const Size(150, 40),
  }) =>
      SendPaymentButton(
        onPressed: onPressed,
        text: 'Retry',
        outlineColor: AppColors.errorColor,
        minimumSize: minimumSize,
        key: key,
      );
}
