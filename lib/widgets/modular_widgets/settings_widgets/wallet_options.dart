import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class WalletOptions extends StatefulWidget {
  final VoidCallback onResyncWalletPressed;

  const WalletOptions(this.onResyncWalletPressed, {Key? key}) : super(key: key);

  @override
  State<WalletOptions> createState() => _WalletOptionsState();
}

class _WalletOptionsState extends State<WalletOptions> {
  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Wallet Options',
      description: 'Other wallet options',
      childBuilder: () => _getWidgetBody(),
    );
  }

  Widget _getWidgetBody() {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel('Delete cache', _getDeleteCacheExpandedWidget()),
        CustomExpandablePanel('Reset wallet', _getResetWalletExpandedWidget()),
      ],
    );
  }

  Column _getResetWalletExpandedWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'This option will erase the wallet files. Make sure you have a '
          'backup first',
          style: Theme.of(context).textTheme.subtitle2,
        ),
        kVerticalSpacing,
        Center(
          child: SettingsButton(
            onPressed: () => NavigationUtils.push(
              context,
              const ResetWalletScreen(),
            ),
            text: 'Reset wallet',
          ),
        ),
      ],
    );
  }

  Widget _getDeleteCacheExpandedWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'This option will delete the wallet cache and close the application',
          style: Theme.of(context).textTheme.subtitle2,
        ),
        kVerticalSpacing,
        Center(
          child: SettingsButton(
            onPressed: () {
              NavigationUtils.pushReplacement(
                context,
                const SplashScreen(
                  deleteCacheFlow: true,
                ),
              );
            },
            text: 'Delete cache',
          ),
        ),
      ],
    );
  }
}
