import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Screen generating and presenting a 12- or 24-word recovery seed for backup.
class NewWalletSeedChoiceScreen extends StatelessWidget {
  /// Creates a [NewWalletSeedChoiceScreen].
  const NewWalletSeedChoiceScreen({
    bool? export,
    this._clearAddressesBox,
    super.key,
  }) : _export = export ?? false;

  final bool _export;
  final Future<void> Function()? _clearAddressesBox;

  @override
  Widget build(BuildContext context) {
    return _View(
      export: _export,
      clearAddressesBox: _clearAddressesBox ?? _defaultClearAddressesBox,
    );
  }

  static Future<void> _defaultClearAddressesBox() async {
    final bool addressesBoxExists = await Hive.boxExists(kAddressesBox);
    if (addressesBoxExists) {
      final Box<dynamic> addressesBox = await Hive.openBox<dynamic>(
        kAddressesBox,
      );
      await addressesBox.clear();
    }
  }
}

class _View extends StatefulWidget {
  const _View({required this._export, required this._clearAddressesBox});

  final bool _export;
  final Future<void> Function() _clearAddressesBox;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  bool _isSeed12Selected = false;
  bool _isSeedSecure = false;
  bool _isSeedWrittenDown = false;

  late final List<String> _generatedSeed24;
  late final List<String> _generatedSeed12;

  final GlobalKey<SeedGridState> _seedGridKey = GlobalKey<SeedGridState>();

  @override
  void initState() {
    super.initState();
    unawaited(_clearCachedAddresses());
    _generatedSeed24 = Mnemonic.generateMnemonic(256).split(' ');
    _generatedSeed12 = Mnemonic.generateMnemonic(128).split(' ');
  }

  Future<void> _clearCachedAddresses() async {
    try {
      await widget._clearAddressesBox();
    } on Object catch (error, stackTrace) {
      Logger(
        'NewWalletSeedChoiceScreen',
      ).log(Level.WARNING, '_clearCachedAddresses', error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: <Widget>[
                const ProgressBar(currentLevel: 1),
                const SizedBox(height: 30),
                Text(
                  context.l10n.thisIsYourWordsSeed(_isSeed12Selected ? 12 : 24),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Text(
                  context.l10n.writeDownAndExportSeedSafely,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                kVerticalSpacing,
                SizedBox(
                  height: 45,
                  child: Visibility(
                    visible: !_isSeedSecure,
                    child: _buildSeedChoice(),
                  ),
                ),
                kVerticalSpacing,
                _buildSeedGrid(),
              ],
            ),
            SizedBox(
              height: 40,
              child: Visibility(
                visible: !_isSeedSecure,
                child: _buildBackUpSeedButton(context),
              ),
            ),
            Column(
              children: <Widget>[
                _buildConfirmSecureCheckbox(context),
                _buildConfirmWrittenDownCheckbox(context),
              ],
            ),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedGrid() {
    return SeedGrid(
      _isSeed12Selected ? _generatedSeed12 : _generatedSeed24,
      enableSeedInputFields: false,
      key: _seedGridKey,
    );
  }

  Widget _buildSeedChoice() {
    return SeedChoice(
      isSeed12Selected: _isSeed12Selected,
      onSeed24Selected: () {
        setState(() {
          _isSeedWrittenDown = false;
          _isSeed12Selected = false;
          _seedGridKey.currentState?.changedSeed(_generatedSeed24);
        });
      },
      onSeed12Selected: () {
        setState(() {
          _isSeedWrittenDown = false;
          _isSeed12Selected = true;
          _seedGridKey.currentState?.changedSeed(_generatedSeed12);
        });
      },
    );
  }

  Widget _buildBackUpSeedButton(BuildContext context) {
    return Consumer<ValueNotifier<List<String>>>(
      builder: (_, ValueNotifier<List<String>> exportedSeed, _) => Container(
        decoration: BoxDecoration(
          color: _isSeedExported(exportedSeed.value)
              ? AppColors.znnColor
              : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: Border.all(color: AppColors.znnColor),
        ),
        child: InkWell(
          onTap: () {
            final String seed =
                (_isSeed12Selected ? _generatedSeed12 : _generatedSeed24).join(
                  ' ',
                );
            NavigationUtils.push(context, ExportWalletInfoScreen(seed));
          },
          child: FocusableActionDetector(
            child: SizedBox(
              height: 50,
              width: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ColoredBox(
                    color: Colors.transparent,
                    child: SvgPicture.asset(
                      'assets/svg/ic_export_seed.svg',
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).textTheme.headlineSmall!.color!,
                        BlendMode.srcIn,
                      ),
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    context.l10n.exportSeed,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmSecureCheckbox(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Checkbox(
          value: _isSeedSecure,
          checkColor: Theme.of(context).colorScheme.primary,
          activeColor: AppColors.znnColor,
          onChanged: (bool? value) {
            setState(() {
              _isSeedSecure = value ?? false;
            });
          },
        ),
        Text(
          context.l10n.backedUpSeedInSafeLocation,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildConfirmWrittenDownCheckbox(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Checkbox(
          value: _isSeedWrittenDown,
          checkColor: Theme.of(context).colorScheme.primary,
          activeColor: AppColors.znnColor,
          onChanged: (bool? value) {
            setState(() {
              _isSeedWrittenDown = value ?? false;
            });
          },
        ),
        Text(
          context.l10n.writtenDownMySeed,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final bool isSeedGridReady =
        !(_seedGridKey.currentState?.continueButtonDisabled ?? false);
    final bool canContinue =
        _isSeedSecure && _isSeedWrittenDown && isSeedGridReady;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OnboardingButton(
          onPressed: () {
            if (widget._export) {
              Navigator.popUntil(
                context,
                ModalRoute.withName(AccessWalletScreen.route),
              );
            } else {
              Navigator.pop(context);
            }
          },
          text: context.l10n.goBack,
        ),
        kSpacingBetweenActionButtons,
        OnboardingButton(
          onPressed: canContinue
              ? () {
                  NavigationUtils.push(
                    context,
                    NewWalletConfirmSeedScreen(
                      _isSeed12Selected ? _generatedSeed12 : _generatedSeed24,
                    ),
                  );
                }
              : null,
          text: context.l10n.continueText,
        ),
      ],
    );
  }

  bool _isSeedExported(List<String> exportedSeeds) => _isSeed12Selected
      ? exportedSeeds.contains(_generatedSeed12.join(' '))
      : exportedSeeds.contains(_generatedSeed24.join(' '));
}
