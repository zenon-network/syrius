import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';

/// A scrollable modal layout with a title, close button, and content.
class BaseModal extends StatelessWidget {
  /// Creates a modal layout containing the supplied title and child.
  const BaseModal({required this._child, required this._title, super.key});

  final Widget _child;
  final String _title;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: kVerticalGap16.height!,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(_title, style: context.textTheme.titleLarge),
                IconButton(
                  onPressed: Navigator.of(context).pop,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            _child,
          ],
        ),
      ),
    );
  }
}
