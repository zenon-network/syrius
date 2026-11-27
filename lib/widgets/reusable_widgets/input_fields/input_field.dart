import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

/// Styled form text field with custom desktop context menu support.
class InputField extends StatefulWidget {
  /// Creates an [InputField].
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

  /// Controller managing the text being edited.
  final TextEditingController controller;

  /// Optional focus node associated with this input field.
  final FocusNode? thisNode;

  /// Optional focus node to advance focus to after submission.
  final FocusNode? nextNode;

  /// Placeholder hint text displayed when the field is empty.
  final String? hintText;

  /// Whether the field accepts user input.
  final bool enabled;

  /// Optional input formatters applied to user edits.
  final List<TextInputFormatter>? inputFormatters;

  /// Optional validation callback returning an error string or `null`.
  final String? Function(String?)? validator;

  /// Optional widget rendered at the trailing edge of the field.
  final Widget? suffixIcon;

  /// Optional size constraints for [suffixIcon].
  final BoxConstraints? suffixIconConstraints;

  /// Left content padding inside the input decoration.
  final double contentLeftPadding;

  /// Optional callback invoked when the field's text changes.
  final Function(String)? onChanged;

  /// Whether entered text should be obscured (e.g. for passwords).
  final bool obscureText;

  /// Optional error text displayed below the input field.
  final String? errorText;

  /// Maximum number of lines for the input field.
  final int maxLines;

  /// Optional callback invoked when the user submits the field.
  final Function(String)? onSubmitted;

  /// Text style applied to user-entered text.
  final TextStyle inputtedTextStyle;

  /// Border displayed when the field is enabled and unfocused.
  final InputBorder? enabledBorder;

  /// Border displayed when the field has focus.
  final InputBorder? focusedBorder;

  /// Border displayed when the field is disabled.
  final InputBorder? disabledBorder;

  /// Border displayed when the field has a validation error.
  final InputBorder? errorBorder;

  /// Border displayed when the field is focused and has a validation error.
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
      contextMenuBuilder: (
        BuildContext context,
        EditableTextState editableTextState,
      ) {
        return AdaptiveTextSelectionToolbar(
            anchors: editableTextState.contextMenuAnchors,
            children: editableTextState.contextMenuButtonItems
                .map((ContextMenuButtonItem buttonItem) {
              return Row(children: <Widget>[
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
      inputFormatters: widget.inputFormatters ?? <TextInputFormatter>[],
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
