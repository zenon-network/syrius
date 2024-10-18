import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class AccessWalletScreen extends StatefulWidget {

  const AccessWalletScreen({super.key});
  static const String route = 'access-wallet-screen';

  @override
  State<AccessWalletScreen> createState() => _AccessWalletScreenState();
}

class _AccessWalletScreenState extends State<AccessWalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: [
            Column(
              children: <Widget>[
                Text(
                  'Welcome',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Text(
                  'Select an option to access your wallet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 50,
                ),
              ],
            ),
            Expanded(
              child: StandardFluidLayout(
                defaultCellHeight: kStaggeredNumOfColumns / 3,
                children: [
                  AccessWalletFluidCell(
                    onPressed: _onCreateWalletButtonPressed,
                    buttonIconLocation: 'assets/svg/ic_create_new.svg',
                    buttonText: 'Create wallet',
                    context: context,
                  ),
                  AccessWalletFluidCell(
                    onPressed: _onImportWalletButtonPressed,
                    buttonIconLocation: 'assets/svg/ic_import_wallet.svg',
                    buttonText: 'Import wallet',
                    context: context,
                  ),
                  AccessWalletFluidCell(
                    onPressed: _onHardwareWalletButtonPressed,
                    buttonIconLocation: 'assets/svg/ic_hardware_wallet.svg',
                    buttonText: 'Hardware wallet',
                    context: context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCreateWalletButtonPressed() {
    NavigationUtils.push(
      context,
      const NewWalletSeedChoiceScreen(
        export: false,
      ),
    );
  }

  void _onImportWalletButtonPressed() {
    NavigationUtils.push(
      context,
      const ImportWalletSeedChoiceScreen(),
    );
  }

  void _onHardwareWalletButtonPressed() {
    NavigationUtils.push(
      context,
      const HardwareWalletDeviceChoiceScreen(),
    );
  }
}
