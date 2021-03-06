import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/screens/onboarding/access_wallet_screen.dart';
import 'package:zenon_syrius_wallet_flutter/screens/onboarding/import_wallet/import_wallet_decrypt_screen.dart';
import 'package:zenon_syrius_wallet_flutter/screens/onboarding/import_wallet/import_wallet_password_screen.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/onboarding_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/progress_bars.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/seed/seed_choice.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/seed/seed_grid.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/select_file_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ImportWalletSeedChoiceScreen extends StatefulWidget {
  const ImportWalletSeedChoiceScreen({Key? key}) : super(key: key);

  @override
  _ImportWalletSeedChoiceScreenState createState() =>
      _ImportWalletSeedChoiceScreenState();
}

class _ImportWalletSeedChoiceScreenState
    extends State<ImportWalletSeedChoiceScreen> {
  bool _isSeed12Selected = false;

  String? _walletFilePath;

  final GlobalKey<SeedGridState> _seedGridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _openHiveAddressesBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: [
                ProgressBar(
                  currentLevel: 1,
                  // If the seed is imported from a file, an extra step to decrypt the file is needed
                  numLevels: _walletFilePath == null ? 4 : 5,
                ),
                const SizedBox(
                  height: 30.0,
                ),
                Text(
                  'Import your wallet',
                  style: Theme.of(context).textTheme.headline1,
                ),
                kVerticalSpacing,
                Text(
                  'Input your seed or import the Seed Vault',
                  style: Theme.of(context).textTheme.headline4,
                ),
                kVerticalSpacing,
                SizedBox(
                  height: 45.0,
                  child: _getSeedChoice(),
                ),
                kVerticalSpacing,
                _getSeedGrid(),
              ],
            ),
            _getUploadFileContainer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _getGoBackButton(),
                kSpacingBetweenActionButtons,
                _getContinueButton()
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getUploadFileContainer() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isSeed12Selected ? 0.0 : 20.0,
      ),
      width: _isSeed12Selected ? 3 * kSeedWordCellWidth : double.infinity,
      child: SelectFileWidget(
          fileExtension: 'json',
          onPathFoundCallback: (String path) {
            setState(() {
              _walletFilePath = path;
              _seedGridKey.currentState!.continueButtonDisabled = false;
            });
          }),
    );
  }

  Widget _getContinueButton() {
    return OnboardingButton(
      onPressed: _seedGridKey.currentState != null &&
                  _seedGridKey.currentState!.continueButtonDisabled == false ||
              _walletFilePath != null
          ? () {
              if (_seedGridKey.currentState!.continueButtonDisabled == false &&
                  _walletFilePath == null) {
                if (Mnemonic.validateMnemonic(
                  _seedGridKey.currentState!.getSeedWords,
                )) {
                  NavigationUtils.push(
                    context,
                    ImportWalletPasswordScreen(
                      _seedGridKey.currentState!.getSeed,
                      progressBarNumLevels: 4,
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Importing seed'),
                      content: const Text('Mnemonic is not valid'),
                      actions: [
                        TextButton(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
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
          : null,
      text: 'Continue',
    );
  }

  Widget _getGoBackButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.popUntil(
          context,
          ModalRoute.withName(AccessWalletScreen.route),
        );
      },
      text: 'Go back',
    );
  }

  Widget _getSeedChoice() {
    return SeedChoice(
      isSeed12Selected: _isSeed12Selected,
      onSeed24Selected: () {
        setState(() {
          _isSeed12Selected = false;
          _seedGridKey.currentState!.changedSeed(
            List.generate(24, (index) => ''),
          );
        });
      },
      onSeed12Selected: () {
        setState(() {
          _isSeed12Selected = true;
          _seedGridKey.currentState!.changedSeed(
            List.generate(12, (index) => ''),
          );
        });
      },
    );
  }

  SeedGrid _getSeedGrid() {
    return SeedGrid(
      _isSeed12Selected
          ? List.generate(
              12,
              (index) => '',
            )
          : List.generate(
              24,
              (index) => '',
            ),
      key: _seedGridKey,
      isContinueButtonDisabled: true,
      onTextFieldChangedCallback: () {
        setState(() {});
      },
    );
  }

  void _openHiveAddressesBox() {
    Hive.boxExists(kAddressesBox).then(
      (bool addressesBoxExists) {
        if (addressesBoxExists) {
          Hive.openBox(kAddressesBox)
              .then((Box addressesBox) => addressesBox.clear());
        }
      },
    );
  }
}
