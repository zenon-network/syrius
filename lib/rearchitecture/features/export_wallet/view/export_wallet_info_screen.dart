import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/export_wallet/view/export_wallet_password_screen.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Step 1 of the Seed Vault export flow explaining offline backup requirements.
class ExportWalletInfoScreen extends StatefulWidget {
  /// Creates an [ExportWalletInfoScreen].
  const ExportWalletInfoScreen(
    this._seed, {
    this._backupWalletFlow = false,
    super.key,
  });

  final String _seed;
  final bool _backupWalletFlow;

  @override
  State<ExportWalletInfoScreen> createState() => _ExportWalletInfoScreenState();
}

class _ExportWalletInfoScreenState extends State<ExportWalletInfoScreen> {
  bool _isSecure = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const ProgressBar(currentLevel: 1, numLevels: 2),
            SvgPicture.asset(
              'assets/svg/ic_export_seed.svg',
              colorFilter: const ColorFilter.mode(
                AppColors.znnColor,
                BlendMode.srcIn,
              ),
              height: 55,
            ),
            Text(
              context.l10n.exportSeedVault,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            _buildExplanationBox(context),
            _buildSeedVaultIcons(context),
            _buildConfirmationCheckbox(context),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationBox(BuildContext context) {
    final double seedFieldsGridWidth = MediaQuery.sizeOf(context).width * 0.5;
    return Container(
      width: seedFieldsGridWidth,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        context.l10n.seedVaultBackupExplanation,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge!.copyWith(color: Colors.white),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildSeedVaultIcons(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: MediaQuery.sizeOf(context).width * 0.2,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 32,
        runSpacing: 16,
        children: <Widget>[
          Column(
            children: <Widget>[
              SvgPicture.asset(
                'assets/svg/ic_seed.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.qsrColor,
                  BlendMode.srcIn,
                ),
                height: 50,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.seed,
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
              const SizedBox(height: 8),
              Text(
                context.l10n.seedVaultKey,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          Column(
            children: <Widget>[
              SvgPicture.asset(
                'assets/svg/ic_vault_seed.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.znnColor,
                  BlendMode.srcIn,
                ),
                height: 50,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.seedVault,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCheckbox(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Checkbox(
          value: _isSecure,
          checkColor: Colors.black,
          activeColor: AppColors.znnColor,
          onChanged: (bool? value) {
            setState(() {
              _isSecure = value ?? false;
            });
          },
        ),
        Flexible(
          child: Text(
            context.l10n.willSecurelyStoreSeedVault,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OnboardingButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          text: context.l10n.goBack,
        ),
        kSpacingBetweenActionButtons,
        OnboardingButton(
          onPressed: _isSecure
              ? () {
                  NavigationUtils.push(
                    context,
                    ExportWalletPasswordScreen(
                      widget._seed,
                      backupWalletFlow: widget._backupWalletFlow,
                    ),
                  );
                }
              : null,
          text: context.l10n.continueText,
        ),
      ],
    );
  }
}
