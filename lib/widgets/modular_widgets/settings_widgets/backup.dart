import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class BackupWidget extends StatefulWidget {
  const BackupWidget({Key? key}) : super(key: key);

  @override
  State<BackupWidget> createState() => _BackupWidgetState();
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
        onPressed: (kWallet is KeyStore) ? _onBackupWalletPressed : null,
        text: 'Backup wallet',
      ),
    );
  }

  void _onBackupWalletPressed() {
    NavigationUtils.push(
      context,
      ExportWalletInfoScreen(
        (kWallet as KeyStore).mnemonic!,
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
