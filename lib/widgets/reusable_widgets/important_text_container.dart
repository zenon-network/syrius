import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class ImportantTextContainer extends StatelessWidget {

  const ImportantTextContainer({
    required this.text,
    this.showBorder = false,
    this.isSelectable = false,
    super.key,
  });
  final String text;
  final bool showBorder;
  final bool isSelectable;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        border: showBorder
            ? Border.all(
                color: AppColors.errorColor,
              )
            : null,
        borderRadius: const BorderRadius.all(
          Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
        child: Row(
          children: [
            const Icon(
              Icons.info,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: isSelectable
                  ? SelectableText(text, style: const TextStyle(fontSize: 14))
                  : Text(text, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
