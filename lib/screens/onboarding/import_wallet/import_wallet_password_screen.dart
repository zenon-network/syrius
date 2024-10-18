import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class ImportWalletPasswordScreen extends StatefulWidget {

  const ImportWalletPasswordScreen(
    this.seed, {
    this.progressBarNumLevels = 5,
    super.key,
  });
  final String seed;
  final int progressBarNumLevels;

  @override
  State<ImportWalletPasswordScreen> createState() =>
      _ImportWalletPasswordScreenState();
}

class _ImportWalletPasswordScreenState
    extends State<ImportWalletPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _passwordKey = GlobalKey();
  final GlobalKey<FormState> _confirmPasswordKey = GlobalKey();

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
                ProgressBar(
                  currentLevel: widget.progressBarNumLevels - 2,
                  numLevels: widget.progressBarNumLevels,
                ),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  'Create a wallet password',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Text(
                  'This is the password that will be required to unlock the wallet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 100,
                ),
                Column(
                  children: [
                    Form(
                      key: _passwordKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: PasswordInputField(
                        hintText: 'Password',
                        controller: _passwordController,
                        validator: InputValidators.validatePassword,
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (value) {
                          if (_arePasswordsValid()) {
                            NavigationUtils.push(
                              context,
                              CreateKeyStoreScreen(
                                widget.seed,
                                _passwordController.text,
                                progressBarNumLevels:
                                    widget.progressBarNumLevels,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    kVerticalSpacing,
                    Form(
                      key: _confirmPasswordKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: PasswordInputField(
                        hintText: 'Confirm password',
                        controller: _confirmPasswordController,
                        validator: (value) =>
                            InputValidators.checkPasswordMatch(
                          _passwordController.text,
                          value,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (value) {
                          if (_arePasswordsValid()) {
                            NavigationUtils.push(
                              context,
                              CreateKeyStoreScreen(
                                widget.seed,
                                _passwordController.text,
                                progressBarNumLevels:
                                    widget.progressBarNumLevels,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    kVerticalSpacing,
                    PasswordProgressBar(
                      password: _passwordController.text,
                      passwordKey: _passwordKey,
                    ),
                  ],
                ),
              ],
            ),
            const DottedBorderInfoWidget(
              text: 'Use a password that has at least 8 characters, one '
                  'number, one uppercase letter, one lowercase letter and '
                  'one symbol',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _getGoBackButton(),
                kSpacingBetweenActionButtons,
                _getContinuePassword(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _arePasswordsValid() {
    return InputValidators.validatePassword(_passwordController.text) == null &&
        InputValidators.checkPasswordMatch(
              _passwordController.text,
              _confirmPasswordController.text,
            ) ==
            null;
  }

  Widget _getGoBackButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.pop(context);
      },
      text: 'Go back',
    );
  }

  Widget _getContinuePassword() {
    return OnboardingButton(
      onPressed: _arePasswordsValid()
          ? () {
              NavigationUtils.push(
                context,
                CreateKeyStoreScreen(
                  widget.seed,
                  _passwordController.text,
                  progressBarNumLevels: widget.progressBarNumLevels,
                ),
              );
            }
          : null,
      text: 'Confirm password',
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
