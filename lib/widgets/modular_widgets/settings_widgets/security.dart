import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const double _kMaxMinutesOfInactivity = 30.0;
const double _kMinUnlockAttempts = 3.0;
const double _kMaxUnlockAttempts = 10.0;

class SecurityWidget extends StatefulWidget {
  final VoidCallback _onChangeAutoLockTime;
  final VoidCallback onStepperNotificationSeeMorePressed;

  const SecurityWidget(
    this._onChangeAutoLockTime, {
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  State createState() {
    return _SecurityWidgetState();
  }
}

class _SecurityWidgetState extends State<SecurityWidget> {
  final GlobalKey<LoadingButtonState> _confirmIntervalButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _autoEraseButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _signButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _signFileButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _verifyButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _verifyFileButtonKey = GlobalKey();

  final TextEditingController _textToBeSignedController =
      TextEditingController();
  final TextEditingController _signedTextController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _textToBeVerifiedController =
      TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  final TextEditingController _publicKeyToBeFilledController =
      TextEditingController();
  final TextEditingController _fileHashController = TextEditingController();
  final TextEditingController _publicKeySignFileController =
      TextEditingController();
  final TextEditingController _fileHashVerifyController =
      TextEditingController();
  final TextEditingController _publicKeyVerifyFileController =
      TextEditingController();

  String? _toBeSignedFilePath;
  String? _toBeVerifiedFilePath;

  double? _autoEraseWalletLimit;
  int? _autoLockWalletMinutes;

  final GlobalKey<SelectFileWidgetState> _signSelectFileWidgetKey = GlobalKey();
  final GlobalKey<SelectFileWidgetState> _verifySelectFileWidgetKey =
      GlobalKey();

  @override
  void initState() {
    super.initState();
    _autoEraseWalletLimit = kAutoEraseWalletLimit;
    _autoLockWalletMinutes = kAutoLockWalletMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Security',
      description: 'Change the security parameters of the wallet',
      childBuilder: () => _getFutureBuilder(context),
    );
  }

  Widget _getFutureBuilder(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: zenon!.defaultKeyPair!.getPublicKey(),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error.toString());
        } else if (snapshot.hasData) {
          _publicKeyController.text = BytesUtils.bytesToHex(snapshot.data!);
          _publicKeySignFileController.text =
              BytesUtils.bytesToHex(snapshot.data!);
          return _getWidgetBody(context);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          'Change password',
          _getChangePasswordExpandedWidget(),
        ),
        CustomExpandablePanel('Auto-lock wallet', _getAutoLockSlider()),
        CustomExpandablePanel('Auto-erase wallet', _getAutoEraseSlider()),
        CustomExpandablePanel('Sign', _getSignExpandedWidget()),
        CustomExpandablePanel('Verify', _getVerifyExpandedWidget()),
        CustomExpandablePanel('Sign file', _getSignFileExpandedWidget()),
        CustomExpandablePanel('Verify file', _getVerifyFileExpandedWidget()),
      ],
    );
  }

  Widget _getChangePasswordExpandedWidget() {
    return Center(
      child: SettingsButton(
        text: 'Change password',
        onPressed: _onChangePasswordPressed,
      ),
    );
  }

  void _onChangePasswordPressed() {
    NavigationUtils.push(
      context,
      ChangeWalletPasswordScreen(
        onStepperNotificationSeeMorePressed:
            widget.onStepperNotificationSeeMorePressed,
      ),
    );
  }

  Widget _getAutoLockSlider() {
    return Column(
      children: [
        CustomSlider(
          description:
              'Lock after $_autoLockWalletMinutes minutes of inactivity',
          startValue: kAutoLockWalletMinutes!.toDouble(),
          maxValue: _kMaxMinutesOfInactivity,
          callback: (double value) {
            setState(() {
              _autoLockWalletMinutes = value.toInt();
            });
          },
        ),
        kVerticalSpacing,
        _getConfirmAutoLockDurationButton(),
      ],
    );
  }

  Widget _getAutoEraseSlider() {
    return Column(
      children: [
        CustomSlider(
          description: 'Erase after ${_autoEraseWalletLimit!.toInt()} '
              'failed password attempts',
          startValue: kAutoEraseWalletLimit,
          min: _kMinUnlockAttempts,
          maxValue: _kMaxUnlockAttempts,
          callback: (double value) {
            setState(() {
              _autoEraseWalletLimit = value;
            });
          },
        ),
        kVerticalSpacing,
        _getConfirmAutoEraseButton(),
      ],
    );
  }

  Widget _getConfirmAutoLockDurationButton() {
    return LoadingButton.settings(
      text: 'Confirm',
      onPressed: _onConfirmAutoLockDurationButtonPressed,
      key: _confirmIntervalButtonKey,
    );
  }

  void _onConfirmAutoLockDurationButtonPressed() async {
    try {
      _confirmIntervalButtonKey.currentState?.animateForward();
      await sharedPrefsService!
          .put(
        kAutoLockWalletMinutesKey,
        _autoLockWalletMinutes,
      )
          .then(
        (value) {
          kAutoLockWalletMinutes = _autoLockWalletMinutes;
          widget._onChangeAutoLockTime();
        },
      );
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Error while confirming auto-lock interval',
      );
    } finally {
      _confirmIntervalButtonKey.currentState?.animateReverse();
    }
  }

  Widget _getConfirmAutoEraseButton() {
    return LoadingButton.settings(
      text: 'Confirm',
      onPressed: _onConfirmAutoEraseButtonPressed,
      key: _autoEraseButtonKey,
    );
  }

  void _onConfirmAutoEraseButtonPressed() async {
    try {
      _autoEraseButtonKey.currentState?.animateForward();
      await sharedPrefsService!
          .put(
        kAutoEraseNumAttemptsKey,
        _autoEraseWalletLimit,
      )
          .then(
        (value) {
          kAutoEraseWalletLimit = _autoEraseWalletLimit;
          sl.get<NotificationsBloc>().addNotification(
                WalletNotification(
                  title: 'Auto-erase attempts limit successfully changed',
                  details: 'The auto-erase limit has now '
                      '$kAutoEraseWalletLimit attempt(s)',
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  id: null,
                  type: NotificationType.autoEraseNumAttemptsChanged,
                ),
              );
        },
      );
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Error while confirming auto-erase limit',
      );
    } finally {
      _autoEraseButtonKey.currentState?.animateReverse();
    }
  }

  Widget _getSignExpandedWidget() {
    return Column(
      children: [
        kVerticalSpacing,
        InputField(
          controller: _textToBeSignedController,
          hintText: 'Enter text',
          onChanged: (String? value) {
            setState(() {});
          },
          suffixIcon: CopyToClipboardIcon(
            _textToBeSignedController.text,
            hoverColor: Colors.transparent,
          ),
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          key: _signButtonKey,
          text: 'Sign',
          onPressed: _textToBeSignedController.text.isNotEmpty
              ? _onSignButtonPressed
              : null,
        ),
        Visibility(
          visible: _signedTextController.text.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10.0,
              ),
              const Text('Signature:'),
              const SizedBox(
                height: 10.0,
              ),
              Row(
                children: [
                  Expanded(
                    child: InputField(
                      enabled: false,
                      controller: _signedTextController,
                    ),
                  ),
                  CopyToClipboardIcon(_signedTextController.text),
                ],
              ),
              const SizedBox(
                height: 10.0,
              ),
              const Text('Public key:'),
              const SizedBox(
                height: 10.0,
              ),
              Row(
                children: [
                  Expanded(
                    child: InputField(
                      enabled: false,
                      controller: _publicKeyController,
                    ),
                  ),
                  CopyToClipboardIcon(_publicKeyController.text),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onSignButtonPressed() async {
    try {
      _signButtonKey.currentState?.animateForward();
      final signedMessage = await walletSign(
        _textToBeSignedController.text.codeUnits,
      );
      setState(() {
        _signedTextController.text = signedMessage;
      });
    } catch (e) {
      NotificationUtils.sendNotificationError(e, 'Error while signing message');
    } finally {
      _signButtonKey.currentState?.animateReverse();
    }
  }

  Widget _getVerifyExpandedWidget() {
    return Column(
      children: [
        kVerticalSpacing,
        InputField(
          onChanged: (value) {
            setState(() {});
          },
          controller: _textToBeVerifiedController,
          hintText: 'Enter message',
          suffixIcon: RawMaterialButton(
            hoverColor: Colors.white12,
            shape: const CircleBorder(),
            onPressed: () {
              setState(() {
                ClipboardUtils.pasteToClipboard(
                  context,
                  (String value) {
                    _textToBeVerifiedController.text = value;
                  },
                );
              });
            },
            child: const Icon(
              Icons.content_paste,
              color: AppColors.darkHintTextColor,
              size: 15.0,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            maxWidth: 45.0,
            maxHeight: 20.0,
          ),
        ),
        kVerticalSpacing,
        InputField(
          onChanged: (value) {
            setState(() {});
          },
          controller: _signatureController,
          hintText: 'Enter signature',
          suffixIcon: RawMaterialButton(
            hoverColor: Colors.white12,
            shape: const CircleBorder(),
            onPressed: () {
              setState(() {
                ClipboardUtils.pasteToClipboard(
                  context,
                  (String value) {
                    _signatureController.text = value;
                  },
                );
              });
            },
            child: const Icon(
              Icons.content_paste,
              color: AppColors.darkHintTextColor,
              size: 15.0,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            maxWidth: 45.0,
            maxHeight: 20.0,
          ),
        ),
        kVerticalSpacing,
        InputField(
          onChanged: (value) {
            setState(() {});
          },
          controller: _publicKeyToBeFilledController,
          hintText: 'Enter public key',
          suffixIcon: RawMaterialButton(
            hoverColor: Colors.white12,
            shape: const CircleBorder(),
            onPressed: () {
              setState(() {
                ClipboardUtils.pasteToClipboard(
                  context,
                  (String value) {
                    _publicKeyToBeFilledController.text = value;
                  },
                );
              });
            },
            child: const Icon(
              Icons.content_paste,
              color: AppColors.darkHintTextColor,
              size: 15.0,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            maxWidth: 45.0,
            maxHeight: 20.0,
          ),
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          key: _verifyButtonKey,
          text: 'Verify',
          onPressed: _textToBeVerifiedController.text.isNotEmpty &&
                  _signatureController.text.isNotEmpty &&
                  _publicKeyToBeFilledController.text.isNotEmpty
              ? _onVerifyButtonPressed
              : null,
        ),
      ],
    );
  }

  Future<void> _onVerifyButtonPressed() async {
    try {
      _verifyButtonKey.currentState?.animateForward();
      bool verified = await Crypto.verify(
        FormatUtils.decodeHexString(_signatureController.text),
        Uint8List.fromList(_textToBeVerifiedController.text.codeUnits),
        FormatUtils.decodeHexString(_publicKeyToBeFilledController.text),
      );
      if (verified) {
        sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: 'Message verified successfully',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details: 'The message: ${_textToBeVerifiedController.text} '
                    'was successfully verified with the signature: '
                    '${_signatureController.text}',
                type: NotificationType.paymentSent,
              ),
            );
        setState(() {
          _textToBeVerifiedController.clear();
          _signatureController.clear();
          _publicKeyToBeFilledController.clear();
        });
      } else {
        throw 'Message or signature invalid';
      }
    } catch (e) {
      NotificationUtils.sendNotificationError(
          e, 'Error while verifying message');
    } finally {
      _verifyButtonKey.currentState?.animateReverse();
    }
  }

  @override
  void dispose() {
    _textToBeSignedController.dispose();
    _signedTextController.dispose();
    _textToBeVerifiedController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Widget _getSignFileExpandedWidget() {
    return Column(
      children: [
        SelectFileWidget(
          onPathFoundCallback: (String path) {
            setState(() {
              _toBeSignedFilePath = path;
            });
          },
          textStyle: Theme.of(context).textTheme.titleMedium,
          key: _signSelectFileWidgetKey,
        ),
        Visibility(
          visible: _toBeSignedFilePath != null,
          child: Column(
            children: [
              kVerticalSpacing,
              LoadingButton.settings(
                key: _signFileButtonKey,
                text: 'Sign file',
                onPressed: _onSignFileButtonPressed,
              ),
            ],
          ),
        ),
        Visibility(
          visible: _fileHashController.text.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              kVerticalSpacing,
              const Text('Signed hash:'),
              kVerticalSpacing,
              Row(
                children: [
                  Expanded(
                    child: InputField(
                      enabled: false,
                      controller: _fileHashController,
                    ),
                  ),
                  CopyToClipboardIcon(_fileHashController.text),
                ],
              ),
              kVerticalSpacing,
              const Text('Public key:'),
              kVerticalSpacing,
              Row(
                children: [
                  Expanded(
                    child: InputField(
                      enabled: false,
                      controller: _publicKeySignFileController,
                    ),
                  ),
                  CopyToClipboardIcon(_publicKeySignFileController.text),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSignFileButtonPressed() async {
    try {
      _signFileButtonKey.currentState?.animateForward();
      File droppedFile = File(
        _toBeSignedFilePath!,
      );
      final fileSignature = await walletSign(Crypto.digest(
        await droppedFile.readAsBytes(),
      ));
      setState(() {
        _fileHashController.text = fileSignature;
        _toBeSignedFilePath = null;
        _signSelectFileWidgetKey.currentState!.resetMessageToUser();
      });
    } catch (e) {
      NotificationUtils.sendNotificationError(e, 'Error while signing message');
    } finally {
      _signFileButtonKey.currentState?.animateReverse();
    }
  }

  Widget _getVerifyFileExpandedWidget() {
    return Column(
      children: [
        SelectFileWidget(
          onPathFoundCallback: (String path) {
            setState(() {
              _toBeVerifiedFilePath = path;
            });
          },
          textStyle: Theme.of(context).textTheme.titleMedium,
          key: _verifySelectFileWidgetKey,
        ),
        Visibility(
          visible: _toBeVerifiedFilePath != null,
          child: Column(
            children: [
              kVerticalSpacing,
              LoadingButton.settings(
                key: _verifyFileButtonKey,
                text: 'Verify file',
                onPressed: _fileHashVerifyController.text.isNotEmpty &&
                        _publicKeyVerifyFileController.text.isNotEmpty
                    ? _onVerifyFileButtonPressed
                    : null,
              ),
            ],
          ),
        ),
        Column(
          children: [
            kVerticalSpacing,
            InputField(
              onChanged: (value) {
                setState(() {});
              },
              controller: _fileHashVerifyController,
              hintText: 'Enter signed hash',
              suffixIcon: RawMaterialButton(
                hoverColor: Colors.white12,
                shape: const CircleBorder(),
                onPressed: () {
                  setState(() {
                    ClipboardUtils.pasteToClipboard(
                      context,
                      (String value) {
                        _fileHashVerifyController.text = value;
                      },
                    );
                  });
                },
                child: const Icon(
                  Icons.content_paste,
                  color: AppColors.darkHintTextColor,
                  size: 15.0,
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                maxWidth: 45.0,
                maxHeight: 20.0,
              ),
            ),
            kVerticalSpacing,
            InputField(
              onChanged: (value) {
                setState(() {});
              },
              controller: _publicKeyVerifyFileController,
              hintText: 'Enter public key',
              suffixIcon: RawMaterialButton(
                hoverColor: Colors.white12,
                shape: const CircleBorder(),
                onPressed: () {
                  setState(() {
                    ClipboardUtils.pasteToClipboard(
                      context,
                      (String value) {
                        _publicKeyVerifyFileController.text = value;
                      },
                    );
                  });
                },
                child: const Icon(
                  Icons.content_paste,
                  color: AppColors.darkHintTextColor,
                  size: 15.0,
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                maxWidth: 45.0,
                maxHeight: 20.0,
              ),
            ),
            kVerticalSpacing
          ],
        ),
      ],
    );
  }

  void _onVerifyFileButtonPressed() async {
    try {
      _verifyFileButtonKey.currentState?.animateForward();
      bool verified = await Crypto.verify(
        FormatUtils.decodeHexString(_fileHashVerifyController.text),
        Uint8List.fromList(Crypto.digest(await File(
          _toBeVerifiedFilePath!,
        ).readAsBytes())),
        FormatUtils.decodeHexString(_publicKeyVerifyFileController.text),
      );
      if (verified) {
        sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: 'File hash verified successfully',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details:
                    'File hash was successfully verified with the signed hash: '
                    '${_fileHashVerifyController.text}',
                type: NotificationType.paymentSent,
              ),
            );
        setState(() {
          _toBeVerifiedFilePath = null;
          _verifySelectFileWidgetKey.currentState!.resetMessageToUser();
          _fileHashVerifyController.clear();
          _publicKeyVerifyFileController.clear();
        });
      } else {
        throw 'Hash or public key invalid';
      }
    } catch (e) {
      NotificationUtils.sendNotificationError(
          e, 'Error while verifying file hash:');
    } finally {
      _verifyFileButtonKey.currentState?.animateReverse();
    }
  }
}
