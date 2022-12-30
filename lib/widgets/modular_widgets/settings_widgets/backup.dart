import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/settings_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_expandable_panel.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';

class BackupWidget extends StatefulWidget {
  const BackupWidget({Key? key}) : super(key: key);

  @override
  _BackupWidgetState createState() => _BackupWidgetState();
}

class _BackupWidgetState extends State<BackupWidget> {
  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Backup',
      description: 'Backup your seed using the syrius standard format JSON '
          '(encrypted, recommended) or show it on the screen (clear text, '
          'not recommended)',
      childBuilder: () => _getWidgetBody(context),
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        CustomExpandablePanel('Backup Wallet', _getBackupButton()),
        CustomExpandablePanel('Dump Mnemonic', _getDumpMnemonicButton()),
      ],
    );
  }

  Widget _getBackupButton() {
    return Center(
      child: SettingsButton(
        onPressed: _onBackupWalletPressed,
        text: 'Backup wallet',
      ),
    );
  }

  void _onBackupWalletPressed() {
    NavigationUtils.push(
      context,
      ExportWalletInfoScreen(
        kKeyStore!.mnemonic!,
        backupWalletFlow: true,
      ),
    );
  }

  Widget _getDumpMnemonicButton() {
    return Center(
      child: SettingsButton(
        onPressed: () {
          NavigationUtils.push(
            context,
            const DumpMnemonicScreen(),
          );
        },
        text: 'Dump Mnemonic',
      ),
    );
  }
}
