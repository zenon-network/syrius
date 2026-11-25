import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays an action to open the Syrius GitHub releases page for updates.
class UpdateCard extends StatelessWidget {
  /// Creates an [UpdateCard].
  const UpdateCard({@visibleForTesting this._onUpdatePressed, super.key});

  final VoidCallback? _onUpdatePressed;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.update,
        description: context.l10n.checkUpdatesForSyriusWallet,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        CustomExpandablePanel(
          context.l10n.checkUpdate,
          _buildCheckUpdateButton(context),
        ),
      ],
    );
  }

  Widget _buildCheckUpdateButton(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: () {
          final VoidCallback? callback = _onUpdatePressed;
          if (callback != null) {
            callback();
          } else {
            unawaited(NavigationUtils.openUrl(kGithubReleasesLink));
          }
        },
        child: Text(context.l10n.update),
      ),
    );
  }
}
