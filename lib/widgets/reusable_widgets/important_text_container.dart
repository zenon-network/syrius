import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class ImportantTextContainer extends StatefulWidget {
  final String text;
  final bool showBorder;
  final bool animateBorder;
  final bool isSelectable;

  const ImportantTextContainer({
    required this.text,
    this.showBorder = false,
    this.animateBorder = false,
    this.isSelectable = false,
    Key? key,
  }) : super(key: key);

  @override
  State<ImportantTextContainer> createState() => _ImportantTextContainerState();
}

class _ImportantTextContainerState extends State<ImportantTextContainer>
    with TickerProviderStateMixin {
  double _animationValue = 8.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2500),
      tween: Tween(begin: 2.0, end: _animationValue),
      curve: Curves.easeInOut,
      onEnd: () {
        if (widget.animateBorder) {
          setState(() {
            _animationValue = _animationValue == 8.0 ? 2.0 : 8.0;
          });
        }
      },
      builder: (_, double value, __) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            border: widget.showBorder
                ? Border.all(
                    width: 1.0,
                    color: AppColors.errorColor,
                  )
                : null,
            boxShadow: widget.showBorder && widget.animateBorder
                ? [
                    BoxShadow(
                        color: AppColors.errorColor.withOpacity(0.35),
                        blurRadius: value,
                        spreadRadius: value)
                  ]
                : null,
            borderRadius: const BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 20.0),
            child: Row(
              children: [
                const Icon(
                  Icons.info,
                  size: 20.0,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 15.0,
                ),
                Expanded(
                  child: widget.isSelectable
                      ? SelectableText(widget.text,
                          style: const TextStyle(fontSize: 14.0))
                      : Text(widget.text,
                          style: const TextStyle(fontSize: 14.0)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
