import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Opens the peer-to-peer swap tutorial when pressed.
class ViewSwapTutorialButton extends StatelessWidget {
  /// Creates a button that links to the swap tutorial.
  const ViewSwapTutorialButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => unawaited(
        NavigationUtils.openUrl(kP2pSwapTutorialLink),
      ),
      label: Text(context.l10n.viewSwapTutorial),
      icon: const Icon(Icons.open_in_new),
      iconAlignment: IconAlignment.end,
    );
  }
}
