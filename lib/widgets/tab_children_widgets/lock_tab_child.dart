import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/screens/splash_screen.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/keystore_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/loading_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/password_input_field.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class LockTabChild extends StatefulWidget {
  final Future<void> Function(String) afterUnlockCallback;
  final Function() afterInitCallback;

  const LockTabChild(this.afterUnlockCallback, this.afterInitCallback,
      {Key? key})
      : super(key: key);

  @override
  _LockTabChildState createState() => _LockTabChildState();
}

class _LockTabChildState extends State<LockTabChild> {
  final TextEditingController _passwordController = TextEditingController();

  String _messageToUser = '';

  final GlobalKey<LoadingButtonState> _actionButtonKey = GlobalKey();

  LoadingButton? _actionButton;

  @override
  void initState() {
    super.initState();
    _actionButton = _getActionButton();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Fontisto.locked,
            color: Color.fromRGBO(63, 63, 63, 1),
            size: 50.0,
          ),
          const SizedBox(
            height: 40.0,
          ),
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headline2,
          ),
          const SizedBox(
            height: 20.0,
          ),
          Text(
            'Enter the password to access the wallet',
            style: Theme.of(context).textTheme.headline4,
          ),
          const SizedBox(
            height: 40.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              PasswordInputField(
                controller: _passwordController,
                hintText: 'Current password',
                onSubmitted: (value) {
                  _actionButton!.onPressed!();
                },
              ),
              const SizedBox(
                width: 10.0,
              ),
              _actionButton!,
            ],
          ),
          const SizedBox(
            height: 30.0,
          ),
          Visibility(
            visible: _messageToUser.isEmpty,
            child:
                (kAutoEraseWalletLimit!.toInt() - kNumFailedUnlockAttempts! ==
                        1)
                    ? Text(
                        'Last attempt. The wallet will be reset if this '
                        'attempt fails',
                        style: Theme.of(context).textTheme.headline4,
                      )
                    : Text(
                        '${kAutoEraseWalletLimit!.toInt() - kNumFailedUnlockAttempts!} attempts left',
                        style: Theme.of(context).textTheme.headline4,
                      ),
          ),
          Visibility(
            visible: _messageToUser.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Text(
                _messageToUser,
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LoadingButton _getActionButton() {
    return LoadingButton.icon(
      onPressed: _onActionButtonPressed,
      key: _actionButtonKey,
      icon: const Icon(
        AntDesign.arrowright,
        color: AppColors.znnColor,
        size: 25.0,
      ),
    );
  }

  void _onError(String errorMessage, Object error) {
    if (_messageToUser.isNotEmpty) {
      setState(() {
        _messageToUser = '';
      });
    }
    NotificationUtils.sendNotificationError(error, errorMessage);
    if (error is IncorrectPasswordException) {
      kNumFailedUnlockAttempts = kNumFailedUnlockAttempts! + 1;
      _saveNumFailedUnlockAttempts(kNumFailedUnlockAttempts);
    }
    if (kNumFailedUnlockAttempts == kAutoEraseWalletLimit) {
      NavigationUtils.pushReplacement(
        context,
        const SplashScreen(
          resetWalletFlow: true,
        ),
      );
    }
  }

  Future<void> _onActionButtonPressed() async {
    if (_passwordController.text.isNotEmpty &&
        _actionButtonKey.currentState!.btnState == ButtonState.idle) {
      try {
        _actionButtonKey.currentState!.animateForward();
        await KeyStoreUtils.decryptKeyStoreFile(
          kKeyStorePath!,
          _passwordController.text,
        ).then((keyStore) => kKeyStore = keyStore);
        if (kWalletInitCompleted == false) {
          setState(() {
            _messageToUser = 'Initializing wallet, please wait';
          });
          await Utils.initWalletAfterDecryption(context);
          widget.afterInitCallback();
        } else {
          await widget.afterUnlockCallback(_passwordController.text);
        }
        _restNumOfFailedAttempts();
        _resetScreenState();
      } on IncorrectPasswordException {
        _onError(
          kIncorrectPasswordNotificationTitle,
          IncorrectPasswordException(),
        );
      } catch (e) {
        _onError(kUnlockFailedNotificationTitle, e);
      } finally {
        _actionButtonKey.currentState?.animateReverse();
      }
    }
  }

  Future<void> _saveNumFailedUnlockAttempts(int? numAttempts) async {
    await sharedPrefsService!.put(kNumUnlockFailedAttemptsKey, numAttempts);
  }

  void _resetScreenState() {
    setState(() {
      _cleanScreen();
    });
  }

  void _cleanScreen() {
    _clearInput();
    _clearMessageToUser();
  }

  void _clearInput() {
    _passwordController.clear();
  }

  void _clearMessageToUser() {
    _messageToUser = '';
  }

  void _restNumOfFailedAttempts() {
    _saveNumFailedUnlockAttempts(0).then(
      (_) {
        kNumFailedUnlockAttempts =
            sharedPrefsService!.get(kNumUnlockFailedAttemptsKey);
      },
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
