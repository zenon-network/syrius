import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/change_wallet_password/change_wallet_password.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_security/settings_security.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const double _kMaxMinutesOfInactivity = 30;
const double _kMinUnlockAttempts = 3;
const double _kMaxUnlockAttempts = 10;

const BoxConstraints _kCompactPasteSuffixConstraints = BoxConstraints(
  maxWidth: 45,
  maxHeight: 20,
);

/// Displays wallet security settings, message signing/verification, and file
/// signing/verification controls in the Settings tab.
class SettingsSecurityCard extends StatelessWidget {
  /// Creates a [SettingsSecurityCard].
  const SettingsSecurityCard({
    required this._onChangeAutoLockTime,
    required this._onStepperNotificationSeeMorePressed,
    this._bloc,
    super.key,
  });

  final VoidCallback _onChangeAutoLockTime;
  final VoidCallback _onStepperNotificationSeeMorePressed;
  final SettingsSecurityBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final SettingsSecurityBloc? injected = _bloc;
    final Widget view = _View(
      onChangeAutoLockTime: _onChangeAutoLockTime,
      onStepperNotificationSeeMorePressed: _onStepperNotificationSeeMorePressed,
    );

    if (injected != null) {
      return BlocProvider<SettingsSecurityBloc>.value(
        value: injected,
        child: view,
      );
    }

    return BlocProvider<SettingsSecurityBloc>(
      create: (_) => SettingsSecurityBloc(),
      child: view,
    );
  }
}

class _View extends StatefulWidget {
  const _View({
    required this._onChangeAutoLockTime,
    required this._onStepperNotificationSeeMorePressed,
  });

  final VoidCallback _onChangeAutoLockTime;
  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final GlobalKey<LoadingButtonState> _confirmIntervalButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _autoEraseButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _signButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _signFileButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _verifyButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _verifyFileButtonKey =
      GlobalKey<LoadingButtonState>();

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

  final GlobalKey<SelectFileWidgetState> _signSelectFileWidgetKey =
      GlobalKey<SelectFileWidgetState>();
  final GlobalKey<SelectFileWidgetState> _verifySelectFileWidgetKey =
      GlobalKey<SelectFileWidgetState>();

  String? _toBeSignedFilePath;
  String? _toBeVerifiedFilePath;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      body: MultiBlocListener(
        listeners: <BlocListener<SettingsSecurityBloc, SettingsSecurityState>>[
          BlocListener<SettingsSecurityBloc, SettingsSecurityState>(
            listenWhen:
                (
                  SettingsSecurityState previous,
                  SettingsSecurityState current,
                ) =>
                    previous.autoLockConfirmedNonce !=
                    current.autoLockConfirmedNonce,
            listener: (_, _) => widget._onChangeAutoLockTime(),
          ),
          BlocListener<SettingsSecurityBloc, SettingsSecurityState>(
            listenWhen:
                (
                  SettingsSecurityState previous,
                  SettingsSecurityState current,
                ) =>
                    previous.messageVerifiedNonce !=
                    current.messageVerifiedNonce,
            listener: (_, _) {
              setState(() {
                _textToBeVerifiedController.clear();
                _signatureController.clear();
                _publicKeyToBeFilledController.clear();
              });
            },
          ),
          BlocListener<SettingsSecurityBloc, SettingsSecurityState>(
            listenWhen:
                (
                  SettingsSecurityState previous,
                  SettingsSecurityState current,
                ) => previous.fileSignedNonce != current.fileSignedNonce,
            listener: (_, _) {
              setState(() {
                _toBeSignedFilePath = null;
                _signSelectFileWidgetKey.currentState?.resetMessageToUser();
              });
            },
          ),
          BlocListener<SettingsSecurityBloc, SettingsSecurityState>(
            listenWhen:
                (
                  SettingsSecurityState previous,
                  SettingsSecurityState current,
                ) => previous.fileVerifiedNonce != current.fileVerifiedNonce,
            listener: (_, _) {
              setState(() {
                _toBeVerifiedFilePath = null;
                _verifySelectFileWidgetKey.currentState?.resetMessageToUser();
                _fileHashVerifyController.clear();
                _publicKeyVerifyFileController.clear();
              });
            },
          ),
        ],
        child: BlocConsumer<SettingsSecurityBloc, SettingsSecurityState>(
          listener: _onStateChanged,
          builder: (BuildContext context, SettingsSecurityState state) {
            return ListView(
              shrinkWrap: true,
              children: <Widget>[
                CustomExpandablePanel(
                  context.l10n.changePassword,
                  _buildChangePasswordPanel(context),
                ),
                CustomExpandablePanel(
                  context.l10n.autoLockWallet,
                  _buildAutoLockSlider(context, state),
                ),
                CustomExpandablePanel(
                  context.l10n.autoEraseWallet,
                  _buildAutoEraseSlider(context, state),
                ),
                CustomExpandablePanel(
                  context.l10n.sign,
                  _buildSignPanel(context, state),
                ),
                CustomExpandablePanel(
                  context.l10n.verify,
                  _buildVerifyPanel(context),
                ),
                CustomExpandablePanel(
                  context.l10n.signFile,
                  _buildSignFilePanel(context, state),
                ),
                CustomExpandablePanel(
                  context.l10n.verifyFile,
                  _buildVerifyFilePanel(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.security,
    description: context.l10n.changeWalletSecurityParameters,
  );

  void _onStateChanged(BuildContext context, SettingsSecurityState state) {
    _syncLoadingButton(_confirmIntervalButtonKey, state.isConfirmingAutoLock);
    _syncLoadingButton(_autoEraseButtonKey, state.isConfirmingAutoErase);
    _syncLoadingButton(_signButtonKey, state.isSigningMessage);
    _syncLoadingButton(_verifyButtonKey, state.isVerifyingMessage);
    _syncLoadingButton(_signFileButtonKey, state.isSigningFile);
    _syncLoadingButton(_verifyFileButtonKey, state.isVerifyingFile);

    if (_signedTextController.text != state.signedMessageSignature) {
      _signedTextController.text = state.signedMessageSignature;
    }
    if (_publicKeyController.text != state.signedMessagePublicKey) {
      _publicKeyController.text = state.signedMessagePublicKey;
    }
    if (_fileHashController.text != state.signedFileHash) {
      _fileHashController.text = state.signedFileHash;
    }
    if (_publicKeySignFileController.text != state.signedFilePublicKey) {
      _publicKeySignFileController.text = state.signedFilePublicKey;
    }
  }

  void _syncLoadingButton(GlobalKey<LoadingButtonState> key, bool isLoading) {
    if (isLoading) {
      key.currentState?.animateForward();
    } else {
      key.currentState?.animateReverse();
    }
  }

  Widget _buildChangePasswordPanel(BuildContext context) {
    return Center(
      child: SettingsButton(
        text: context.l10n.changePassword,
        onPressed: () {
          NavigationUtils.push(
            context,
            ChangeWalletPasswordScreen(
              onStepperNotificationSeeMorePressed:
                  widget._onStepperNotificationSeeMorePressed,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoLockSlider(
    BuildContext context,
    SettingsSecurityState state,
  ) {
    return Column(
      children: <Widget>[
        CustomSlider(
          description: context.l10n.lockAfterMinutesOfInactivity(
            state.autoLockMinutes,
          ),
          startValue: state.autoLockMinutes.toDouble(),
          maxValue: _kMaxMinutesOfInactivity,
          callback: (double value) {
            context.read<SettingsSecurityBloc>().add(
              SettingsSecurityAutoLockChanged(minutes: value.toInt()),
            );
          },
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          text: context.l10n.confirm,
          onPressed: () {
            context.read<SettingsSecurityBloc>().add(
              SettingsSecurityAutoLockConfirmed(
                errorTitle: context.l10n.errorConfirmingAutoLockInterval,
              ),
            );
          },
          key: _confirmIntervalButtonKey,
        ),
      ],
    );
  }

  Widget _buildAutoEraseSlider(
    BuildContext context,
    SettingsSecurityState state,
  ) {
    return Column(
      children: <Widget>[
        CustomSlider(
          description: context.l10n.eraseAfterFailedPasswordAttempts(
            state.autoEraseAttempts.toInt(),
          ),
          startValue: state.autoEraseAttempts,
          min: _kMinUnlockAttempts,
          maxValue: _kMaxUnlockAttempts,
          callback: (double value) {
            context.read<SettingsSecurityBloc>().add(
              SettingsSecurityAutoEraseChanged(attempts: value),
            );
          },
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          text: context.l10n.confirm,
          onPressed: () {
            context.read<SettingsSecurityBloc>().add(
              SettingsSecurityAutoEraseConfirmed(
                notificationTitle: context.l10n.autoEraseLimitChanged,
                notificationDetails: context.l10n.autoEraseLimitNowAttempts(
                  state.autoEraseAttempts.toString(),
                ),
                errorTitle: context.l10n.errorConfirmingAutoEraseLimit,
              ),
            );
          },
          key: _autoEraseButtonKey,
        ),
      ],
    );
  }

  Widget _buildSignPanel(BuildContext context, SettingsSecurityState state) {
    return Column(
      children: <Widget>[
        kVerticalSpacing,
        InputField(
          controller: _textToBeSignedController,
          hintText: context.l10n.enterText,
          onChanged: (String value) {
            setState(() {});
          },
          suffixIcon: PasteContentButton(
            controller: _textToBeSignedController,
            iconColor: AppColors.znnColor,
            iconSize: 15,
            hoverColor: Colors.transparent,
            tooltip: context.l10n.pasteFromClipboard,
            onPasted: (_) {
              if (!mounted) {
                return;
              }
              setState(() {});
            },
          ),
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          key: _signButtonKey,
          text: context.l10n.sign,
          onPressed: _textToBeSignedController.text.isNotEmpty
              ? () {
                  context.read<SettingsSecurityBloc>().add(
                    SettingsSecuritySignMessageRequested(
                      message: _textToBeSignedController.text,
                      errorTitle: context.l10n.errorSigningMessage,
                    ),
                  );
                }
              : null,
        ),
        Visibility(
          visible: state.signedMessageSignature.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 10),
              Text('${context.l10n.signature}:'),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: InputField(
                      enabled: false,
                      controller: _signedTextController,
                    ),
                  ),
                  CopyToClipboardButton(state.signedMessageSignature),
                ],
              ),
              const SizedBox(height: 10),
              Text('${context.l10n.publicKey}:'),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: InputField(
                      enabled: false,
                      controller: _publicKeyController,
                    ),
                  ),
                  CopyToClipboardButton(state.signedMessagePublicKey),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyPanel(BuildContext context) {
    final bool canVerify =
        _textToBeVerifiedController.text.isNotEmpty &&
        _signatureController.text.isNotEmpty &&
        _publicKeyToBeFilledController.text.isNotEmpty;

    return Column(
      children: <Widget>[
        kVerticalSpacing,
        _buildCompactPasteInputField(
          context: context,
          controller: _textToBeVerifiedController,
          hintText: context.l10n.enterMessage,
        ),
        kVerticalSpacing,
        _buildCompactPasteInputField(
          context: context,
          controller: _signatureController,
          hintText: context.l10n.enterSignature,
        ),
        kVerticalSpacing,
        _buildCompactPasteInputField(
          context: context,
          controller: _publicKeyToBeFilledController,
          hintText: context.l10n.enterPublicKey,
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          key: _verifyButtonKey,
          text: context.l10n.verify,
          onPressed: canVerify
              ? () {
                  final String message = _textToBeVerifiedController.text;
                  final String signature = _signatureController.text;
                  context.read<SettingsSecurityBloc>().add(
                    SettingsSecurityVerifyMessageRequested(
                      message: message,
                      signature: signature,
                      publicKey: _publicKeyToBeFilledController.text,
                      successTitle: context.l10n.messageVerifiedSuccessfully,
                      successDetails: context.l10n.messageVerifiedWithSignature(
                        message,
                        signature,
                      ),
                      invalidMessage: context.l10n.messageOrSignatureInvalid,
                      errorTitle: context.l10n.errorVerifyingMessage,
                    ),
                  );
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSignFilePanel(
    BuildContext context,
    SettingsSecurityState state,
  ) {
    return Column(
      children: <Widget>[
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
            children: <Widget>[
              kVerticalSpacing,
              LoadingButton.settings(
                key: _signFileButtonKey,
                text: context.l10n.signFile,
                onPressed: _toBeSignedFilePath != null
                    ? () {
                        context.read<SettingsSecurityBloc>().add(
                          SettingsSecuritySignFileRequested(
                            filePath: _toBeSignedFilePath!,
                            errorTitle: context.l10n.errorSigningMessage,
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
        Visibility(
          visible: state.signedFileHash.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              kVerticalSpacing,
              Text('${context.l10n.signedHash}:'),
              kVerticalSpacing,
              Row(
                children: <Widget>[
                  Expanded(
                    child: InputField(
                      enabled: false,
                      controller: _fileHashController,
                    ),
                  ),
                  CopyToClipboardButton(state.signedFileHash),
                ],
              ),
              kVerticalSpacing,
              Text('${context.l10n.publicKey}:'),
              kVerticalSpacing,
              Row(
                children: <Widget>[
                  Expanded(
                    child: InputField(
                      enabled: false,
                      controller: _publicKeySignFileController,
                    ),
                  ),
                  CopyToClipboardButton(state.signedFilePublicKey),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyFilePanel(BuildContext context) {
    final bool canVerifyFile =
        _toBeVerifiedFilePath != null &&
        _fileHashVerifyController.text.isNotEmpty &&
        _publicKeyVerifyFileController.text.isNotEmpty;

    return Column(
      children: <Widget>[
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
            children: <Widget>[
              kVerticalSpacing,
              LoadingButton.settings(
                key: _verifyFileButtonKey,
                text: context.l10n.verifyFile,
                onPressed: canVerifyFile
                    ? () {
                        final String signedHash =
                            _fileHashVerifyController.text;
                        context.read<SettingsSecurityBloc>().add(
                          SettingsSecurityVerifyFileRequested(
                            filePath: _toBeVerifiedFilePath!,
                            signedHash: signedHash,
                            publicKey: _publicKeyVerifyFileController.text,
                            successTitle:
                                context.l10n.fileHashVerifiedSuccessfully,
                            successDetails: context.l10n
                                .fileHashVerifiedWithSignedHash(signedHash),
                            invalidMessage: context.l10n.hashOrPublicKeyInvalid,
                            errorTitle: context.l10n.errorVerifyingFileHash,
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
        kVerticalSpacing,
        _buildCompactPasteInputField(
          context: context,
          controller: _fileHashVerifyController,
          hintText: context.l10n.enterSignedHash,
        ),
        kVerticalSpacing,
        _buildCompactPasteInputField(
          context: context,
          controller: _publicKeyVerifyFileController,
          hintText: context.l10n.enterPublicKey,
        ),
        kVerticalSpacing,
      ],
    );
  }

  Widget _buildCompactPasteInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
  }) {
    return InputField(
      onChanged: (String value) {
        setState(() {});
      },
      controller: controller,
      hintText: hintText,
      suffixIcon: PasteContentButton(
        controller: controller,
        hoverColor: Colors.white12,
        iconColor: AppColors.darkHintTextColor,
        iconSize: 15,
        // Verify fields cap suffix height at 20 px, so zero padding avoids
        // clipping the 15 px icon.
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: context.l10n.pasteFromClipboard,
        onPasted: (_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        },
      ),
      suffixIconConstraints: _kCompactPasteSuffixConstraints,
    );
  }

  @override
  void dispose() {
    _textToBeSignedController.dispose();
    _signedTextController.dispose();
    _publicKeyController.dispose();
    _textToBeVerifiedController.dispose();
    _signatureController.dispose();
    _publicKeyToBeFilledController.dispose();
    _fileHashController.dispose();
    _publicKeySignFileController.dispose();
    _fileHashVerifyController.dispose();
    _publicKeyVerifyFileController.dispose();
    super.dispose();
  }
}
