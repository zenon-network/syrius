import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// Warns the user about the experimental nature of P2P swaps.
class P2pSwapWarningModal extends StatelessWidget {
  /// Creates a P2P swap warning modal.
  const P2pSwapWarningModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: context.l10n.p2pSwapWarningTitle,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: <Widget>[
        kVerticalGap16,
        Text(
          context.l10n.p2pSwapWarningDescription,
          style: context.textTheme.bodyLarge,
        ),
        kVerticalGap32,
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.continueText,
            ),
          ),
        ),
      ],
    );
  }
}
