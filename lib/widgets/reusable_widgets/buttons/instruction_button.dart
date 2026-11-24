import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_info_text.dart';

class InstructionButton extends StatefulWidget {
  const InstructionButton({
    required this._text,
    required this._isEnabled,
    required this._isLoading,
    required this._onPressed,
    required this._loadingText,
    this._instructionText,
    super.key,
  });

  final String _text;
  final bool _isEnabled;
  final bool _isLoading;
  final VoidCallback _onPressed;
  final String? _instructionText;
  final String _loadingText;

  @override
  State<InstructionButton> createState() => _InstructionButtonState();
}

class _InstructionButtonState extends State<InstructionButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (widget._isEnabled && !widget._isLoading)
          ? widget._onPressed
          : null,
      child: AnimatedCrossFade(
        duration: Duration(milliseconds: widget._isLoading ? 1000 : 10),
        firstCurve: Curves.easeInOut,
        firstChild: Visibility(
          visible: !widget._isLoading,
          child: Text(
            widget._isEnabled ? widget._text : (widget._instructionText ?? ''),
          ),
        ),
        secondChild: LoadingInfoText(text: widget._loadingText),
        crossFadeState: widget._isLoading
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
      ),
    );
  }
}
