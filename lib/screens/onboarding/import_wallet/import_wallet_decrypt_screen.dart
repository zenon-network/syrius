import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ImportWalletDecryptScreen extends StatefulWidget {
  final String path;

  const ImportWalletDecryptScreen(this.path, {Key? key}) : super(key: key);

  @override
  State<ImportWalletDecryptScreen> createState() =>
      _ImportWalletDecryptScreenState();
}

class _ImportWalletDecryptScreenState extends State<ImportWalletDecryptScreen> {
  String? _passwordErrorText;

  final TextEditingController _passwordController = TextEditingController();

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
            Column(
              children: [
                const ProgressBar(
                  currentLevel: 2,
                ),
                const SizedBox(
                  height: 30.0,
                ),
                Text(
                  'Unlock your Seed Vault',
                  style: Theme.of(context).textTheme.headline1,
                ),
                kVerticalSpacing,
                Text(
                  'Input the Seed Vault Key to continue',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
            PasswordInputField(
              hintText: 'Password',
              controller: _passwordController,
              onChanged: (value) {
                setState(() {});
              },
              errorText: _passwordErrorText,
              onSubmitted: (value) {
                if (_passwordController.text.isNotEmpty) {
                  _loadingButton.onPressed!();
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _getGoBackButton(),
                kSpacingBetweenActionButtons,
                _getDecryptKeyStoreFileViewModel(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LoadingButton _getLoadingButton(DecryptKeyStoreBloc model) {
    return LoadingButton.onboarding(
      key: _loadingButtonKey,
      onPressed: _passwordController.text.isNotEmpty
          ? () async {
              _loadingButtonKey.currentState!.animateForward();
              await model.decryptKeyStoreFile(
                widget.path,
                _passwordController.text,
              );
            }
          : null,
      text: 'Continue',
    );
  }

  Widget _getGoBackButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.pop(context);
      },
      text: 'Go back',
    );
  }

  _getDecryptKeyStoreFileViewModel() {
    return ViewModelBuilder<DecryptKeyStoreBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen((keyStore) {
          if (keyStore != null) {
            _loadingButtonKey.currentState!.animateReverse();
            setState(() {
              _passwordErrorText = null;
            });
            NavigationUtils.push(
              context,
              ImportWalletPasswordScreen(keyStore.mnemonic!),
            );
          }
        }, onError: (error) {
          _loadingButtonKey.currentState!.animateReverse();
          if (error is IncorrectPasswordException) {
            setState(() {
              _passwordErrorText = 'Incorrect password';
            });
          } else {
            setState(() {
              _passwordErrorText = error.toString();
            });
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

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
