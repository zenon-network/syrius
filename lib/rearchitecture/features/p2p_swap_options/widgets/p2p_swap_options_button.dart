import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// A button displaying a P2P swap action and its description.
class P2pSwapOptionsButton extends StatelessWidget {
  /// Creates a P2P swap action button.
  const P2pSwapOptionsButton({
    required this._title,
    required this._subtitle,
    required this._onClick,
    super.key,
  });

  final VoidCallback _onClick;
  final String _title;
  final String _subtitle;

  @override
  Widget build(BuildContext context) {
    final Widget title = Text(
      _title,
    );

    final Widget subtitle = Text(
      _subtitle,
      textAlign: TextAlign.left,
      style: const TextStyle(
        color: AppColors.subtitleColor,
      ),
    );

    return Material(
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        tileColor: context.themeData.inputDecorationTheme.fillColor,
        title: title,
        subtitle: subtitle,
        trailing: const Icon(Icons.keyboard_arrow_right),
        onTap: _onClick,
      ),
    );
  }
}
