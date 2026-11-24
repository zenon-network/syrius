import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/buttons.dart';

/// Displays a copyable warning message in an emphasized card.
class Warning extends StatelessWidget {
  /// Creates a warning card for the supplied text.
  const Warning({
    required this._text,
    super.key,
  });

  final String _text;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: AppColors.errorColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: kHorizontalGap16.width!,
          children: <Widget>[
            const Icon(
              Icons.info,
              color: AppColors.errorColor,
            ),
            Expanded(
              child: Text(_text),
            ),
            CopyToClipboardButton(
              _text,
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
