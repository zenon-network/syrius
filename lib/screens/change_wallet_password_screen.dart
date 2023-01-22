import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ChangeWalletPasswordScreen extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const ChangeWalletPasswordScreen({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  State<ChangeWalletPasswordScreen> createState() =>
      _ChangeWalletPasswordScreenState();
}

class _ChangeWalletPasswordScreenState
    extends State<ChangeWalletPasswordScreen> {
  String? _currentPassErrorText;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _currentPasswordKey = GlobalKey();
  final GlobalKey<FormState> _newPasswordKey = GlobalKey();
  final GlobalKey<FormState> _confirmPasswordKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _loadingButtonKey = GlobalKey();

  late LoadingButton _loadingButton;

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
            NotificationWidget(
              onSeeMorePressed: widget.onStepperNotificationSeeMorePressed,
            ),
            Text(
              'Change wallet password',
              style: Theme.of(context).textTheme.headline1,
            ),
            Column(
              children: [
                Form(
                  key: _currentPasswordKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: PasswordInputField(
                    errorText: _currentPassErrorText,
                    controller: _currentPasswordController,
                    hintText: 'Current password',
                    onChanged: (value) {
                      setState(() {
                        if (_currentPassErrorText != null) {
                          _currentPassErrorText = null;
                        }
                      });
                    },
                  ),
                ),
                kVerticalSpacing,
                Form(
                  key: _newPasswordKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: PasswordInputField(
                    controller: _newPasswordController,
                    validator: InputValidators.validatePassword,
                    onChanged: (value) {
                      setState(() {});
                    },
                    hintText: 'New password',
                  ),
                ),
                kVerticalSpacing,
                Form(
                  key: _confirmPasswordKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: PasswordInputField(
                    controller: _confirmPasswordController,
                    validator: (value) => InputValidators.checkPasswordMatch(
                      _newPasswordController.text,
                      value,
                    ),
                    hintText: 'Repeat new password',
                    onSubmitted: (value) {
                      if (_arePasswordsValid()) {
                        _loadingButton.onPressed!();
                      }
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(
                  height: 35.0,
                ),
                PasswordProgressBar(
                  password: _newPasswordController.text,
                  passwordKey: _newPasswordKey,
                ),
              ],
            ),
            const DottedBorderInfoWidget(
              text: 'Use a password that has at least 8 characters, '
                  'one number, one uppercase letter, one lowercase '
                  'letter and one symbol',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _getPassiveButton(),
                kSpacingBetweenActionButtons,
                _getDecryptKeyStoreFileViewModel(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPassiveButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.pop(context, false);
      },
      text: 'Go back',
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    String mnemonic = kKeyStore!.mnemonic!;
    String oldKeyStorePath = kKeyStorePath!;
    await KeyStoreUtils.createKeyStore(
      mnemonic,
      newPassword,
      keyStoreName:
          '${await kKeyStore!.getKeyPair(0).address}_${DateTime.now().millisecondsSinceEpoch}',
    );
    await FileUtils.deleteFile(oldKeyStorePath);
    if (!mounted) return;
    Navigator.pop(context);
  }

  bool _arePasswordsValid() {
    return _currentPassErrorText == null &&
        InputValidators.validatePassword(_newPasswordController.text) == null &&
        InputValidators.checkPasswordMatch(
              _newPasswordController.text,
              _confirmPasswordController.text,
            ) ==
            null;
  }

  Widget _getDecryptKeyStoreFileViewModel() {
    return ViewModelBuilder<DecryptKeyStoreBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen((keyStore) async {
          if (keyStore != null) {
            setState(() {
              _currentPassErrorText = null;
            });
            try {
              await _changePassword(
                _newPasswordController.text,
                _newPasswordController.text,
              );
            } catch (e) {
              NotificationUtils.sendNotificationError(
                e,
                'An error occurred while trying to change password',
              );
            } finally {
              _loadingButtonKey.currentState!.animateReverse();
            }
          }
        }, onError: (e) {
          _loadingButtonKey.currentState!.animateReverse();
          if (e is IncorrectPasswordException) {
            setState(() {
              _currentPassErrorText = 'Incorrect password';
            });
          } else {
            NotificationUtils.sendNotificationError(
              e,
              'An error occurred while trying to decrypt wallet',
            );
          }
        });
      },
      builder: (_, model, __) {
        _loadingButton = _getLoadingButton(model);
        return _getLoadingButton(model);
      },
      viewModelBuilder: () => DecryptKeyStoreBloc(),
    );
  }

  LoadingButton _getLoadingButton(DecryptKeyStoreBloc model) {
    return LoadingButton.onboarding(
      key: _loadingButtonKey,
      onPressed: _arePasswordsValid()
          ? () {
              _loadingButtonKey.currentState!.animateForward();
              model.decryptKeyStoreFile(
                kKeyStorePath!,
                _currentPasswordController.text,
              );
            }
          : null,
      text: 'Change password',
    );
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
