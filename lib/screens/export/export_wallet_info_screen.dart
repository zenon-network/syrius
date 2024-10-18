import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class ExportWalletInfoScreen extends StatefulWidget {

  const ExportWalletInfoScreen(
    this.seed, {
    this.backupWalletFlow = false,
    super.key,
  });
  final String seed;
  final bool backupWalletFlow;

  @override
  State<ExportWalletInfoScreen> createState() => _ExportWalletInfoScreenState();
}

class _ExportWalletInfoScreenState extends State<ExportWalletInfoScreen> {
  bool? _isSecure = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const ProgressBar(
              currentLevel: 1,
              numLevels: 2,
            ),
            Container(
              color: Colors.transparent,
              child: SvgPicture.asset(
                'assets/svg/ic_export_seed.svg',
                colorFilter:
                    const ColorFilter.mode(AppColors.znnColor, BlendMode.srcIn),
                height: 55,
              ),
            ),
            Text(
              'Export Seed Vault',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            _getSeedFieldsGrid(),
            _getSecureSeedInfo(),
            _secureSeedCheckBoxContainer(),
            _getActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _getSeedFieldsGrid() {
    final seedFieldsGridWidth = MediaQuery.of(context).size.width * 0.5;
    const text = 'A Seed Vault is an encrypted file for backing up your Seed.'
        ' The Seed is encrypted with a Seed Vault Key and cannot be accessed '
        'without it. Make sure you backup your Seed Vault in multiple offline locations '
        '(e.g. USB, external HDD) and do not lose your Seed Vault Key.'
        " If you lose the Seed Vault file or you don't remember the Seed Vault "
        'Key you lose access to your funds.';
    return Container(
      width: seedFieldsGridWidth,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 50,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Colors.white,
            ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _getSecureSeedInfo() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                color: Colors.transparent,
                child: SvgPicture.asset(
                  'assets/svg/ic_seed.svg',
                  colorFilter: const ColorFilter.mode(
                      AppColors.qsrColor, BlendMode.srcIn,),
                  height: 50,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
              ),
              Text(
                'Seed',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          Column(
            children: <Widget>[
              const Icon(
                SimpleLineIcons.key,
                size: 50,
                color: AppColors.errorColor,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
              ),
              Text(
                'Seed Vault Key',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          Column(
            children: <Widget>[
              Container(
                color: Colors.transparent,
                child: SvgPicture.asset(
                  'assets/svg/ic_vault_seed.svg',
                  colorFilter: const ColorFilter.mode(
                      AppColors.znnColor, BlendMode.srcIn,),
                  height: 50,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
              ),
              Text(
                'Seed Vault',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secureSeedCheckBoxContainer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Checkbox(
          value: _isSecure,
          checkColor: Colors.black,
          activeColor: AppColors.znnColor,
          onChanged: (bool? value) {
            setState(() {
              _isSecure = value;
            });
          },
        ),
        Text(
          'I will securely store the Seed Vault & Seed Vault Key',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _getActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OnboardingButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          text: 'Go back',
        ),
        kSpacingBetweenActionButtons,
        OnboardingButton(
          onPressed: _isSecure!
              ? () {
                  NavigationUtils.push(
                    context,
                    ExportWalletPasswordScreen(
                      widget.seed,
                      backupWalletFlow: widget.backupWalletFlow,
                    ),
                  );
                }
              : null,
          text: 'Continue',
        ),
      ],
    );
  }
}
