import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class InputField extends StatefulWidget {

  const InputField({
    required this.controller,
    this.maxLines = 1,
    this.thisNode,
    this.hintText,
    this.nextNode,
    this.enabled = true,
    this.inputFormatters,
    this.validator,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.contentLeftPadding = kContentPadding,
    this.onChanged,
    this.obscureText = false,
    this.errorText,
    this.onSubmitted,
    this.inputtedTextStyle = const TextStyle(
      fontSize: 14,
      color: AppColors.znnColor,
    ),
    this.disabledBorder,
    this.enabledBorder,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    super.key,
  });
  final TextEditingController controller;
  final FocusNode? thisNode;
  final FocusNode? nextNode;
  final String? hintText;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final double contentLeftPadding;
  final Function(String)? onChanged;
  final bool obscureText;
  final String? errorText;
  final int maxLines;
  final Function(String)? onSubmitted;
  final TextStyle inputtedTextStyle;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? disabledBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;

  @override
  State createState() {
    return _InputFieldState();
  }
}

class _InputFieldState extends State<InputField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar(
            anchors: editableTextState.contextMenuAnchors,
            children: editableTextState.contextMenuButtonItems
                .map((ContextMenuButtonItem buttonItem) {
              return Row(children: [
                Expanded(
                    child: TextButton(
                  onPressed: buttonItem.onPressed,
                  style: TextButton.styleFrom(
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                      AdaptiveTextSelectionToolbar.getButtonLabel(
                          context, buttonItem,),
                      style: Theme.of(context).textTheme.bodyMedium,),
                ),),
              ],);
            }).toList(),);
      },
      maxLines: widget.maxLines,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters ?? [],
      enabled: widget.enabled,
      controller: widget.controller,
      focusNode: widget.thisNode,
      onFieldSubmitted: widget.onSubmitted,
      style: widget.inputtedTextStyle,
      decoration: InputDecoration(
        enabledBorder: widget.enabledBorder,
        disabledBorder: widget.disabledBorder,
        focusedBorder: widget.focusedBorder,
        errorBorder: widget.errorBorder,
        focusedErrorBorder: widget.focusedBorder,
        errorText: widget.errorText,
        errorMaxLines: 2,
        contentPadding: EdgeInsets.only(
          left: widget.contentLeftPadding,
          right: kContentPadding,
          top: kContentPadding,
          bottom: kContentPadding,
        ),
        suffixIcon: widget.suffixIcon,
        suffixIconConstraints: widget.suffixIconConstraints,
        filled: true,
        hintText: widget.hintText,
      ),
    );
  }
}
