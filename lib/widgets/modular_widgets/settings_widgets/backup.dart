import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class BackupWidget extends StatefulWidget {
  const BackupWidget({super.key});

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
        CustomExpandablePanel('Backup Wallet', _getBackupWalletButton()),
        CustomExpandablePanel('Dump Mnemonic', _getDumpMnemonicButton()),
      ],
    );
  }

  Widget _getBackupWalletButton() {
    return Center(
      child: SettingsButton(
        onPressed: (!kWalletFile!.isHardwareWallet)
            ? _onBackupWalletPressed
            : null,
        text: 'Backup wallet',
      ),
    );
  }

  Future<void> _onBackupWalletPressed() async {
    kWalletFile!
        .access((wallet) => Future.value((wallet as KeyStore).mnemonic!))
        .then((value) => NavigationUtils.push(
              context,
              ExportWalletInfoScreen(
                value,
                backupWalletFlow: true,
              ),
            ),);
  }

  Widget _getDumpMnemonicButton() {
    return Center(
      child: SettingsButton(
        onPressed: (!kWalletFile!.isHardwareWallet)
            ? _onDumpMnemonicPressed
            : null,
        text: 'Dump Mnemonic',
      ),
    );
  }

  void _onDumpMnemonicPressed() {
    NavigationUtils.push(
      context,
      const DumpMnemonicScreen(),
    );
  }
}
