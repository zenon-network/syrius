import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DumpMnemonicScreen extends StatefulWidget {
  const DumpMnemonicScreen({super.key});

  @override
  State<DumpMnemonicScreen> createState() => _DumpMnemonicScreenState();
}

class _DumpMnemonicScreenState extends State<DumpMnemonicScreen> {
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<LoadingButtonState> _continueButtonKey = GlobalKey();

  LoadingButton? _continueButton;

  String? _passwordError;

  List<String>? _seedWords;

  @override
  Widget build(BuildContext context) {
    _continueButton = _getContinueButton();
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Visibility(
              visible: _seedWords == null,
              child: Text(
                'Enter the wallet password to dump the mnemonic',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            Visibility(
              visible: _seedWords == null,
              child: PasswordInputField(
                controller: _passwordController,
                hintText: 'Current password',
                onSubmitted: (value) {
                  _continueButton!.onPressed!();
                },
                onChanged: (value) {
                  setState(() {});
                },
                errorText: _passwordError,
              ),
            ),
            if (_seedWords != null)
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  child: SeedGrid(
                    _seedWords!,
                    enableSeedInputFields: false,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getLockButton(),
                Visibility(
                  visible: _seedWords == null,
                  child: Row(
                    children: [
                      kSpacingBetweenActionButtons,
                      _continueButton!,
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Widget _getLockButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      text: _seedWords != null ? 'Lock' : 'Go back',
    );
  }

  Future<void> _onContinueButtonPressed() async {
    if (_passwordController.text.isNotEmpty) {
      try {
        _continueButtonKey.currentState!.animateForward();
        final walletFile = await WalletUtils.decryptWalletFile(
          kWalletPath!,
          _passwordController.text,
        );
        walletFile.open().then((wallet) {
          setState(() {
            _passwordController.clear();
            _seedWords = (wallet as KeyStore).mnemonic!.split(' ');
            _passwordError = null;
          });
        });
      } on IncorrectPasswordException {
        setState(() {
          _passwordError = kIncorrectPasswordNotificationTitle;
        });
      } catch (e) {
        setState(() {
          _passwordError = e.toString();
        });
      } finally {
        _continueButtonKey.currentState?.animateReverse();
      }
    }
  }

  LoadingButton _getContinueButton() {
    return LoadingButton.onboarding(
      onPressed:
          _passwordController.text.isNotEmpty ? _onContinueButtonPressed : null,
      text: 'Continue',
      key: _continueButtonKey,
    );
  }
}
