import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Entry screen letting the user create, import, or connect a hardware wallet.
class AccessWalletScreen extends StatelessWidget {
  /// Creates an [AccessWalletScreen].
  const AccessWalletScreen({super.key});

  /// Named route for [AccessWalletScreen].
  static const String route = 'access-wallet-screen';

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: <Widget>[
            _buildHeader(context),
            Expanded(child: _buildOptionsGrid(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          context.l10n.welcome,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        kVerticalSpacing,
        Text(
          context.l10n.selectOptionToAccessWallet,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildOptionsGrid(BuildContext context) {
    return StandardFluidLayout(
      defaultCellHeight: kStaggeredNumOfColumns / 3,
      children: <FluidCell>[
        AccessWalletFluidCell(
          onPressed: () => _onCreateWalletPressed(context),
          buttonIconLocation: 'assets/svg/ic_create_new.svg',
          buttonText: context.l10n.createWallet,
          context: context,
        ),
        AccessWalletFluidCell(
          onPressed: () => _onImportWalletPressed(context),
          buttonIconLocation: 'assets/svg/ic_import_wallet.svg',
          buttonText: context.l10n.importWallet,
          context: context,
        ),
        AccessWalletFluidCell(
          onPressed: () => _onHardwareWalletPressed(context),
          buttonIconLocation: 'assets/svg/ic_hardware_wallet.svg',
          buttonText: context.l10n.hardwareWallet,
          context: context,
        ),
      ],
    );
  }

  void _onCreateWalletPressed(BuildContext context) {
    NavigationUtils.push(
      context,
      const NewWalletSeedChoiceScreen(export: false),
    );
  }

  void _onImportWalletPressed(BuildContext context) {
    NavigationUtils.push(context, const ImportWalletSeedChoiceScreen());
  }

  void _onHardwareWalletPressed(BuildContext context) {
    NavigationUtils.push(context, const HardwareWalletDeviceChoiceScreen());
  }
}
