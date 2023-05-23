import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/copy_to_clipboard_icon.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? valueToShow;
  final Widget? prefixWidget;
  final bool canBeCopied;

  const DetailRow({
    required this.label,
    required this.value,
    this.valueToShow,
    this.prefixWidget,
    this.canBeCopied = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.0, color: AppColors.subtitleColor)),
        Row(
          children: [
            prefixWidget ?? Container(),
            if (prefixWidget != null)
              const SizedBox(
                width: 5.0,
              ),
            Text(valueToShow ?? value,
                style: const TextStyle(
                    fontSize: 12.0, color: AppColors.subtitleColor)),
            Visibility(
              visible: canBeCopied,
              child: CopyToClipboardIcon(
                value,
                iconColor: AppColors.subtitleColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.only(left: 8.0),
              ),
            ),
          ],
        )
      ],
    );
  }
}
