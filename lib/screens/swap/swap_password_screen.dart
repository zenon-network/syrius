import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SwapPasswordScreen extends StatefulWidget {
  final String path;

  const SwapPasswordScreen(this.path, {Key? key}) : super(key: key);

  @override
  _SwapPasswordScreenState createState() => _SwapPasswordScreenState();
}

class _SwapPasswordScreenState extends State<SwapPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<LoadingButtonState> _loadingButtonKey = GlobalKey();

  String? _errorText;

  late LoadingButton _loadingButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 30.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const ProgressBar(
              currentLevel: 3,
              numLevels: 4,
            ),
            Text(
              'Swap wallet',
              style: Theme.of(context).textTheme.headline1,
            ),
            Text(
              'Please input the password for the \'.dat\' wallet file in '
              'order to continue',
              style: Theme.of(context).textTheme.headline4,
            ),
            Material(
              color: Colors.transparent,
              child: PasswordInputField(
                onSubmitted: (value) {
                  if (_passwordController.text.isNotEmpty) {
                    _loadingButton.onPressed!();
                  } else {
                    setState(() {
                      _errorText = 'Please insert a password';
                    });
                  }
                },
                errorText: _errorText,
                controller: _passwordController,
                onChanged: (value) {
                  setState(() {});
                },
                hintText: 'Wallet password',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                getPassiveButton(),
                const SizedBox(
                  width: 70.0,
                ),
                _getReadWalletViewModel(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget getPassiveButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.pop(context);
      },
      text: 'Go back',
    );
  }

  LoadingButton _getLoadingButton(ReadWalletBloc readWalletViewModel) {
    return LoadingButton.onboarding(
      key: _loadingButtonKey,
      onPressed: _passwordController.text.isNotEmpty
          ? () {
              _loadingButtonKey.currentState!.animateForward();
              readWalletViewModel.readWallet(
                  widget.path, _passwordController.text);
            }
          : null,
      text: 'Decrypt',
    );
  }

  Widget _getReadWalletViewModel() {
    return ViewModelBuilder<ReadWalletBloc>.reactive(
      onModelReady: (model) {
        model.stream.listen(
          (swapFileEntries) async {
            if (swapFileEntries != null) {
              var assetsModel = GetAssetsBloc();
              assetsModel.stream.listen(
                (swapAssetsAndEntries) async {
                  if (swapAssetsAndEntries != null) {
                    _loadingButtonKey.currentState!.animateReverse();
                    setState(() {
                      _errorText = null;
                    });
                    NavigationUtils.push(
                      context,
                      SwapTransferBalanceScreen(
                        swapAssetsAndEntries,
                        _passwordController.text,
                      ),
                    );
                  }
                },
                onError: (error) {
                  _loadingButtonKey.currentState!.animateReverse();
                  setState(() {
                    _errorText = error.toString();
                  });
                },
              );
              await assetsModel.getAssetAndSwapFileEntries(swapFileEntries);
            }
          },
          onError: (error) {
            _loadingButtonKey.currentState!.animateReverse();
            setState(() {
              _errorText = error.toString();
            });
          },
        );
      },
      builder: (_, model, __) {
        _loadingButton = _getLoadingButton(model);
        return _loadingButton;
      },
      viewModelBuilder: () => ReadWalletBloc(),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
