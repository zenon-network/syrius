import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/decrypt_wallet_file_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_sync_service.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_local_storage_api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/legacy_htlc_swaps_migrator.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ChangeWalletPasswordScreen extends StatefulWidget {
  const ChangeWalletPasswordScreen({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;

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
          vertical: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            NotificationWidget(
              onSeeMorePressed: widget.onStepperNotificationSeeMorePressed,
            ),
            Text(
              'Change wallet password',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Column(
              children: <Widget>[
                Form(
                  key: _currentPasswordKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: PasswordInputField(
                    errorText: _currentPassErrorText,
                    controller: _currentPasswordController,
                    hintText: 'Current password',
                    onChanged: (String value) {
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
                    onChanged: (String value) {
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
                    validator: (String? value) =>
                        InputValidators.checkPasswordMatch(
                          _newPasswordController.text,
                          value,
                        ),
                    hintText: 'Repeat new password',
                    onSubmitted: (String value) {
                      if (_arePasswordsValid()) {
                        _loadingButton.onPressed!();
                      }
                    },
                    onChanged: (String value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(
                  height: 35,
                ),
                PasswordProgressBar(
                  password: _newPasswordController.text,
                  passwordKey: _newPasswordKey,
                ),
              ],
            ),
            const DottedBorderInfoWidget(
              text:
                  'Use a password that has at least 8 characters, '
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
    final HtlcSwapSyncService handler = sl<HtlcSwapSyncService>();
    final HtlcSwapLocalStorageApi dataProvider = sl<HtlcSwapLocalStorageApi>();
    final List<int> oldEncryptionKey = Crypto.digest(
      utf8.encode(currentPassword),
    );
    final List<int> newEncryptionKey = Crypto.digest(utf8.encode(newPassword));

    await handler.stop();
    try {
      if (kDefaultAddressList.isNotEmpty && kDefaultAddressList.first != null) {
        await sl<LegacyHtlcSwapsMigrator>().migrateIfNeeded(
          walletBaseAddress: WalletUtils.baseAddress.toString(),
          encryptionKey: oldEncryptionKey,
        );
      }
      await dataProvider.beginRekey(
        oldEncryptionKey: oldEncryptionKey,
        newEncryptionKey: newEncryptionKey,
      );
      try {
        await kWalletFile!.changePassword(currentPassword, newPassword);
      } catch (_) {
        await dataProvider.rollbackRekey(oldEncryptionKey);
        rethrow;
      }
      await dataProvider.commitRekey();
    } finally {
      handler.start();
    }
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
    return ViewModelBuilder<DecryptWalletFileBloc>.reactive(
      onViewModelReady: (DecryptWalletFileBloc model) {
        model.stream.listen(
          (WalletFile? walletFile) async {
            if (walletFile != null) {
              setState(() {
                _currentPassErrorText = null;
              });
              try {
                await _changePassword(
                  _currentPasswordController.text,
                  _newPasswordController.text,
                );
              } catch (e) {
                await NotificationUtils.sendNotificationError(
                  e,
                  'An error occurred while trying to change password',
                );
              } finally {
                _loadingButtonKey.currentState!.animateReverse();
              }
            }
          },
          onError: (e) async {
            _loadingButtonKey.currentState!.animateReverse();
            if (e is IncorrectPasswordException) {
              setState(() {
                _currentPassErrorText = 'Incorrect password';
              });
            } else {
              await NotificationUtils.sendNotificationError(
                e,
                'An error occurred while trying to decrypt wallet',
              );
            }
          },
        );
      },
      builder: (_, DecryptWalletFileBloc model, __) {
        _loadingButton = _getLoadingButton(model);
        return _getLoadingButton(model);
      },
      viewModelBuilder: DecryptWalletFileBloc.new,
    );
  }

  LoadingButton _getLoadingButton(DecryptWalletFileBloc model) {
    return LoadingButton.onboarding(
      key: _loadingButtonKey,
      onPressed: _arePasswordsValid()
          ? () {
              _loadingButtonKey.currentState!.animateForward();
              model.decryptWalletFile(
                kWalletPath!,
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
