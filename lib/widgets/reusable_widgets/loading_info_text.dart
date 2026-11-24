import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

class LoadingInfoText extends StatelessWidget {
  const LoadingInfoText({
    required this._text,
    this._tooltipText,
    super.key,
  });

  final String _text;
  final String? _tooltipText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SyriusLoadingWidget(
          size: 16,
          strokeWidth: 2,
        ),
        kHorizontalGap8,
        Text(
          _text,
        ),
        if (_tooltipText != null)
          Row(
            children: <Widget>[
              kHorizontalGap4,
              Tooltip(
                message: _tooltipText,
                child: const Icon(
                  Icons.help,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
