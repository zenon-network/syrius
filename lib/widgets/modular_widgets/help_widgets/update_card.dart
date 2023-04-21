import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class UpdateCard extends StatelessWidget {
  const UpdateCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Update',
      description: 'Check updates for the Syrius wallet',
      childBuilder: () => _getWidgetBody(context),
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          'Check update',
          _getCheckUpdateExpandableChild(context),
        ),
      ],
    );
  }

  Widget _getCheckUpdateExpandableChild(BuildContext context) {
    return Center(
      child: SettingsButton(
        onPressed: () => NavigationUtils.openUrl(kGithubReleasesLink),
        text: 'Update',
      ),
    );
  }
}
