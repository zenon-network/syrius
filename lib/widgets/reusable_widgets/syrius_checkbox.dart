import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Branded [Checkbox] styled with Syrius theme colors.
class SyriusCheckbox extends Checkbox {
  /// Creates a [SyriusCheckbox].
  SyriusCheckbox({
    // Preserves the Checkbox.onChanged callback signature for external callers.
    // ignore: avoid_positional_boolean_parameters
    required Function(bool?) super.onChanged,
    required super.value,
    required BuildContext context,
    super.key,
  }) : super(
          checkColor: Theme.of(context).scaffoldBackgroundColor,
          activeColor: AppColors.znnColor,
        );
}
