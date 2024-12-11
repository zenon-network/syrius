import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class PasswordInputField extends StatefulWidget {

  const PasswordInputField({
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.errorText,
    super.key,
  });
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
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
