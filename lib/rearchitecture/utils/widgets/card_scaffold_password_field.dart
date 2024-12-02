import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// A TextField for entering the wallet password
class CardScaffoldPasswordField extends StatelessWidget {
  /// Creates a new instance.
  const CardScaffoldPasswordField({
    required this.controller,
    required this.obscureText,
    required this.onSuffixIconPressed,
    required this.onSubmitted,
    this.errorText,
    super.key,
  });

  /// Controller that holds the inputted text
  final TextEditingController controller;
  /// Text that will appear under the text field, if it's not null
  final String? errorText;
  /// Callback triggered when input is submitted
  final void Function(String) onSubmitted;
  /// Whether or not to obscure the password
  final bool obscureText;
  /// Callback triggered when the suffix icon is pressed
  final VoidCallback onSuffixIconPressed;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        errorText: errorText,
        hintText: context.l10n.password,
        suffixIcon: IconButton(
          onPressed: onSuffixIconPressed,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.znnColor,
          ),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
