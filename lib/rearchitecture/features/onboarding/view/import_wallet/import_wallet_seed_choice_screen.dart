import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Screen allowing the user to import a wallet via mnemonic words or
/// Seed Vault.
class ImportWalletSeedChoiceScreen extends StatelessWidget {
  /// Creates an [ImportWalletSeedChoiceScreen].
  const ImportWalletSeedChoiceScreen({this._clearAddressesBox, super.key});

  final Future<void> Function()? _clearAddressesBox;

  @override
  Widget build(BuildContext context) {
    return _View(
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
  const _View({required this._clearAddressesBox});

  final Future<void> Function() _clearAddressesBox;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  bool _isSeed12Selected = false;
  String? _walletFilePath;

  final GlobalKey<SeedGridState> _seedGridKey = GlobalKey<SeedGridState>();

  @override
  void initState() {
    super.initState();
    unawaited(_clearCachedAddresses());
  }

  Future<void> _clearCachedAddresses() async {
    try {
      await widget._clearAddressesBox();
    } on Object catch (error, stackTrace) {
      Logger(
        'ImportWalletSeedChoiceScreen',
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
                ProgressBar(
                  currentLevel: 1,
                  // Importing from a file adds a decrypt step.
                  numLevels: _walletFilePath == null ? 4 : 5,
                ),
                const SizedBox(height: 30),
                Text(
                  context.l10n.importYourWallet,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Text(
                  context.l10n.inputSeedOrImportSeedVault,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                kVerticalSpacing,
                SizedBox(height: 45, child: _buildSeedChoice()),
                kVerticalSpacing,
                _buildSeedGrid(),
              ],
            ),
            _buildUploadFileContainer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildGoBackButton(context),
                kSpacingBetweenActionButtons,
                _buildContinueButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadFileContainer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _isSeed12Selected ? 0 : 20),
      width: _isSeed12Selected ? 3 * kSeedWordCellWidth : double.infinity,
      child: SelectFileWidget(
        fileExtension: 'json',
        onPathFoundCallback: (String path) {
          setState(() {
            _walletFilePath = path;
            _seedGridKey.currentState?.continueButtonDisabled = false;
          });
        },
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final SeedGridState? seedGridState = _seedGridKey.currentState;
    final bool canContinue =
        (seedGridState != null &&
            seedGridState.continueButtonDisabled == false) ||
        _walletFilePath != null;

    return OnboardingButton(
      onPressed: canContinue ? () => _onContinuePressed(context) : null,
      text: context.l10n.continueText,
    );
  }

  void _onContinuePressed(BuildContext context) {
    final SeedGridState? seedGridState = _seedGridKey.currentState;
    if (seedGridState != null &&
        seedGridState.continueButtonDisabled == false &&
        _walletFilePath == null) {
      if (Mnemonic.validateMnemonic(seedGridState.getSeedWords)) {
        NavigationUtils.push(
          context,
          ImportWalletPasswordScreen(
            seedGridState.getSeed,
            progressBarNumLevels: 4,
          ),
        );
      } else {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(context.l10n.importingSeed),
              content: Text(context.l10n.mnemonicIsNotValid),
              actions: <Widget>[
                TextButton(
                  child: Text(context.l10n.ok),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        );
      }
    } else if (_walletFilePath != null) {
      NavigationUtils.push(
        context,
        ImportWalletDecryptScreen(_walletFilePath!),
      );
    }
  }

  Widget _buildGoBackButton(BuildContext context) {
    return OnboardingButton(
      onPressed: () {
        Navigator.popUntil(
          context,
          ModalRoute.withName(AccessWalletScreen.route),
        );
      },
      text: context.l10n.goBack,
    );
  }

  Widget _buildSeedChoice() {
    return SeedChoice(
      isSeed12Selected: _isSeed12Selected,
      onSeed24Selected: () {
        setState(() {
          _isSeed12Selected = false;
          _seedGridKey.currentState?.changedSeed(List<String>.filled(24, ''));
        });
      },
      onSeed12Selected: () {
        setState(() {
          _isSeed12Selected = true;
          _seedGridKey.currentState?.changedSeed(List<String>.filled(12, ''));
        });
      },
    );
  }

  Widget _buildSeedGrid() {
    return SeedGrid(
      List<String>.filled(_isSeed12Selected ? 12 : 24, ''),
      key: _seedGridKey,
      isContinueButtonDisabled: true,
      onTextFieldChangedCallback: () => setState(() {}),
    );
  }
}
