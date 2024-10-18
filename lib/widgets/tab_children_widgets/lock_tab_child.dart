import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/init_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class LockTabChild extends StatefulWidget {

  const LockTabChild(this.afterUnlockCallback, this.afterInitCallback,
      {super.key,});
  final Future<void> Function(String) afterUnlockCallback;
  final Function() afterInitCallback;

  @override
  State<LockTabChild> createState() => _LockTabChildState();
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Fontisto.locked,
            color: AppColors.znnColor,
            size: 50,
          ),
          const SizedBox(
            height: 40,
          ),
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Enter the password to access the wallet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(
            height: 40,
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
                width: 10,
              ),
              _actionButton!,
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          Visibility(
            visible: _messageToUser.isEmpty,
            child:
                (kAutoEraseWalletLimit!.toInt() - kNumFailedUnlockAttempts! ==
                        1)
                    ? Text(
                        'Last attempt. The wallet will be reset if this '
                        'attempt fails',
                        style: Theme.of(context).textTheme.headlineSmall,
                      )
                    : Text(
                        '${kAutoEraseWalletLimit!.toInt() - kNumFailedUnlockAttempts!} attempts left',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
          ),
          Visibility(
            visible: _messageToUser.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Text(
                _messageToUser,
                style: Theme.of(context).textTheme.bodyLarge,
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
        size: 25,
      ),
    );
  }

  Future<void> _onError(String errorMessage, Object error) async {
    if (_messageToUser.isNotEmpty) {
      setState(() {
        _messageToUser = '';
      });
    }
    await NotificationUtils.sendNotificationError(error, errorMessage);
    if (error is IncorrectPasswordException) {
      kNumFailedUnlockAttempts = kNumFailedUnlockAttempts! + 1;
      await _saveNumFailedUnlockAttempts(kNumFailedUnlockAttempts);
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
        kWalletFile = await WalletUtils.decryptWalletFile(
          kWalletPath!,
          _passwordController.text,
        );
        if (kWalletInitCompleted == false) {
          setState(() {
            _messageToUser = 'Initializing wallet, please wait';
          });
          await InitUtils.initWalletAfterDecryption(
              Crypto.digest(utf8.encode(_passwordController.text)),);
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
      } on LedgerError catch (e) {
        _onError('Ledger: ${e.toFriendlyString()}', e);
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
    setState(_cleanScreen);
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
