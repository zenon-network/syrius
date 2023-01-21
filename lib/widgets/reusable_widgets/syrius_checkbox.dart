import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class SyriusCheckbox extends Checkbox {
  SyriusCheckbox({
    Key? key,
    required Function(bool?) onChanged,
    required bool? value,
    required BuildContext context,
  }) : super(
          key: key,
          onChanged: onChanged,
          value: value,
          checkColor: Theme.of(context).scaffoldBackgroundColor,
          activeColor: AppColors.znnColor,
        );
}
