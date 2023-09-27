import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_info_text.dart';

class InstructionButton extends StatefulWidget {
  final String text;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;
  final String? instructionText;
  final String? loadingText;

  const InstructionButton({
    required this.text,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
    this.instructionText,
    this.loadingText,
    Key? key,
  }) : super(key: key);

  @override
  State<InstructionButton> createState() => _InstructionButtonState();
}

class _InstructionButtonState extends State<InstructionButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            (widget.isEnabled && !widget.isLoading) ? widget.onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.znnColor,
          disabledBackgroundColor: AppColors.znnColor.withOpacity(0.1),
        ),
        child: AnimatedCrossFade(
          duration: Duration(milliseconds: widget.isLoading ? 1000 : 10),
          firstCurve: Curves.easeInOut,
          firstChild: Visibility(
            visible: !widget.isLoading,
            child: Opacity(
              opacity: widget.isEnabled ? 1.0 : 0.3,
              child: Text(
                widget.isEnabled ? widget.text : (widget.instructionText ?? ''),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          secondChild: SizedBox(
            width: double.infinity,
            child: LoadingInfoText(text: widget.loadingText ?? ''),
          ),
          crossFadeState: widget.isLoading
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ),
    );
  }
}
