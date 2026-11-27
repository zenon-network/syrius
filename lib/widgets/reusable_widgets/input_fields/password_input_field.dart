import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Password input field with a visibility toggle button.
class PasswordInputField extends StatefulWidget {
  /// Creates a [PasswordInputField].
  const PasswordInputField({
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.errorText,
    super.key,
  });

  /// Controller managing the password input text.
  final TextEditingController controller;

  /// Placeholder hint text displayed when empty.
  final String hintText;

  /// Optional callback invoked when the user submits the field.
  final void Function(String)? onSubmitted;

  /// Optional callback invoked whenever the password text changes.
  final void Function(String)? onChanged;

  /// Optional form validator returning an error message or `null`.
  final String? Function(String?)? validator;

  /// Optional error message displayed below the input field.
  final String? errorText;

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kPasswordInputFieldWidth,
      child: InputField(
        controller: widget.controller,
        obscureText: _obscureText,
        suffixIcon: InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          child: SizedBox(
            height: 10,
            width: 10,
            child: Icon(
              _obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.znnColor,
            ),
          ),
        ),
        hintText: widget.hintText,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        validator: widget.validator,
        errorText: widget.errorText,
      ),
    );
  }
}
