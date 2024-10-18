import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class NewWalletSeedChoiceScreen extends StatefulWidget {

  const NewWalletSeedChoiceScreen({super.key, this.export});
  final bool? export;

  @override
  State<NewWalletSeedChoiceScreen> createState() =>
      _NewWalletSeedChoiceScreenState();
}

class _NewWalletSeedChoiceScreenState extends State<NewWalletSeedChoiceScreen> {
  bool _isSeed12Selected = false;
  bool? _isSeedSecure = false;
  bool? _isSeedWrittenDown = false;

  late List<String> _generatedSeed24;
  late List<String> _generatedSeed12;

  final GlobalKey<SeedGridState> _seedGridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _openHiveAddressesBox();
    _generatedSeed24 = Mnemonic.generateMnemonic(256).split(' ');
    _generatedSeed12 = Mnemonic.generateMnemonic(128).split(' ');
  }

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
            Column(
              children: [
                const ProgressBar(
                  currentLevel: 1,
                ),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  _isSeed12Selected
                      ? 'This is your 12 words seed'
                      : 'This is your 24 words seed',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Text(
                  'Please carefully write down your seed and export it to a safe location',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                kVerticalSpacing,
                SizedBox(
                  height: 45,
                  child: Visibility(
                    visible: !_isSeedSecure!,
                    child: _getSeedChoice(),
                  ),
                ),
                kVerticalSpacing,
                _getSeedGrid(),
              ],
            ),
            SizedBox(
              height: 40,
              child: Visibility(
                visible: !_isSeedSecure!,
                child: _getBackUpSeedContainer(),
              ),
            ),
            Column(
              children: [
                _getConfirmSecureCheckboxContainer(),
                _getConfirmWrittenDownCheckbox(),
              ],
            ),
            _getActionButtons(),
          ],
        ),
      ),
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

  SeedGrid _getSeedGrid() {
    return SeedGrid(
      _isSeed12Selected ? _generatedSeed12 : _generatedSeed24,
      enableSeedInputFields: false,
      key: _seedGridKey,
    );
  }

  Widget _getSeedChoice() {
    return SeedChoice(
      isSeed12Selected: _isSeed12Selected,
      onSeed24Selected: () {
        setState(
          () {
            _isSeedWrittenDown = false;
            _isSeed12Selected = false;
            _seedGridKey.currentState!.changedSeed(
              _isSeed12Selected ? _generatedSeed12 : _generatedSeed24,
            );
          },
        );
      },
      onSeed12Selected: () {
        setState(() {
          _isSeedWrittenDown = false;
          _isSeed12Selected = true;
          _seedGridKey.currentState!.changedSeed(
            _isSeed12Selected ? _generatedSeed12 : _generatedSeed24,
          );
        });
      },
    );
  }

  Widget _getBackUpSeedContainer() {
    return Consumer<ValueNotifier<List<String>>>(
      builder: (_, exportedSeed, __) => Container(
        decoration: BoxDecoration(
            color: _isSeedExported(exportedSeed.value)
                ? AppColors.znnColor
                : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            border: Border.all(
              color: AppColors.znnColor,
            ),),
        child: InkWell(
          child: FocusableActionDetector(
            child: SizedBox(
              height: 50,
              width: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    color: Colors.transparent,
                    child: SvgPicture.asset(
                      'assets/svg/ic_export_seed.svg',
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).textTheme.headlineSmall!.color!,
                          BlendMode.srcIn,),
                      height: 18,
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Text(
                    'Export Seed',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            if (_isSeed12Selected) {
              NavigationUtils.push(
                context,
                ExportWalletInfoScreen(
                  _generatedSeed12.join(' '),
                ),
              );
            } else {
              NavigationUtils.push(
                context,
                ExportWalletInfoScreen(
                  _generatedSeed24.join(' '),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _getConfirmSecureCheckboxContainer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Checkbox(
          value: _isSeedSecure,
          checkColor: Theme.of(context).colorScheme.primary,
          activeColor: AppColors.znnColor,
          onChanged: (bool? value) {
            setState(() {
              _isSeedSecure = value;
            });
          },
        ),
        Text(
          'I have backed up my seed in a safe location',
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
            if (widget.export!) {
              Navigator.popUntil(
                context,
                ModalRoute.withName(AccessWalletScreen.route),
              );
            } else {
              Navigator.pop(context);
            }
          },
          text: 'Go back',
        ),
        kSpacingBetweenActionButtons,
        OnboardingButton(
          onPressed: _isSeedSecure! &&
                  _isSeedWrittenDown! &&
                  !_seedGridKey.currentState!.continueButtonDisabled!
              ? () {
                  if (_isSeed12Selected) {
                    NavigationUtils.push(
                      context,
                      NewWalletConfirmSeedScreen(_generatedSeed12),
                    );
                  } else {
                    NavigationUtils.push(
                      context,
                      NewWalletConfirmSeedScreen(_generatedSeed24),
                    );
                  }
                }
              : null,
          text: 'Continue',
        ),
      ],
    );
  }

  Widget _getConfirmWrittenDownCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Checkbox(
          value: _isSeedWrittenDown,
          checkColor: Theme.of(context).colorScheme.primary,
          activeColor: AppColors.znnColor,
          onChanged: (bool? value) {
            setState(() {
              _isSeedWrittenDown = value;
            });
          },
        ),
        Text(
          'I have written down my seed',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  bool _isSeedExported(List<String> exportedSeeds) => _isSeed12Selected
      ? exportedSeeds.contains(_generatedSeed12.join(' '))
      : exportedSeeds.contains(_generatedSeed24.join(' '));
}
