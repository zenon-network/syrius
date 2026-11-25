import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// A reusable icon button that pastes non-empty text from the clipboard.
///
/// Updates the optional controller and/or invokes the `onPasted` callback only
/// if the button is still mounted when the asynchronous clipboard read
/// completes.
class PasteContentButton extends StatelessWidget {
  /// Creates a [PasteContentButton].
  const PasteContentButton({
    this._controller,
    this._onPasted,
    this._iconColor,
    this._iconSize,
    this._padding,
    this._constraints,
    this._hoverColor,
    this._tooltip,
    super.key,
  }) : assert(
         _controller != null || _onPasted != null,
         'At least one of controller or onPasted must be provided.',
       );

  final TextEditingController? _controller;
  final ValueChanged<String>? _onPasted;
  final Color? _iconColor;
  final double? _iconSize;
  final EdgeInsetsGeometry? _padding;
  final BoxConstraints? _constraints;
  final Color? _hoverColor;
  final String? _tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      hoverColor: _hoverColor,
      padding: _padding,
      constraints: _constraints,
      tooltip: _tooltip,
      onPressed: () {
        ClipboardUtils.pasteToClipboard(
          callback: (String value) {
            if (!context.mounted) {
              return;
            }
            _controller?.text = value;
            _onPasted?.call(value);
          },
        );
      },
      icon: Icon(Icons.content_paste, color: _iconColor, size: _iconSize),
    );
  }
}
