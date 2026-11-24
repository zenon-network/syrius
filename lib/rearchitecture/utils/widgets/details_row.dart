import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/copy_to_clipboard_button.dart';

/// Displays a labeled value with an optional copy action and prefix.
class DetailsRow extends StatelessWidget {
  /// Creates a row for displaying a detail label and value.
  const DetailsRow({
    required this._label,
    required this._value,
    this._valueToShow,
    this._prefixWidget,
    this._canBeCopied = true,
    super.key,
  });

  final String _label;
  final String _value;
  final String? _valueToShow;
  final Widget? _prefixWidget;
  final bool _canBeCopied;

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle = context.textTheme.bodySmall;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          _label,
          style: textStyle,
        ),
        Row(
          spacing: kHorizontalGap4.width!,
          children: <Widget>[
            if (_prefixWidget != null) _prefixWidget,
            Text(
              _valueToShow ?? _value,
              style: textStyle,
            ),
            if (_canBeCopied)
              CopyToClipboardButton(
                _value,
              ),
          ],
        ),
      ],
    );
  }
}
