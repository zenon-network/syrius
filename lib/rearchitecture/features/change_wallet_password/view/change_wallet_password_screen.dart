import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/change_wallet_password/change_wallet_password.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Full-screen workflow for changing the wallet password while atomically
/// migrating and rekeying encrypted HTLC swap storage.
class ChangeWalletPasswordScreen extends StatelessWidget {
  /// Creates a [ChangeWalletPasswordScreen].
  const ChangeWalletPasswordScreen({
    required this._onStepperNotificationSeeMorePressed,
    this._bloc,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final ChangeWalletPasswordBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final ChangeWalletPasswordBloc? injected = _bloc;
    final Widget view = _View(
      onStepperNotificationSeeMorePressed: _onStepperNotificationSeeMorePressed,
    );
    if (injected != null) {
      return BlocProvider<ChangeWalletPasswordBloc>.value(
        value: injected,
        child: view,
      );
    }

    return BlocProvider<ChangeWalletPasswordBloc>(
      create: (_) => ChangeWalletPasswordBloc(),
      child: view,
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this._onStepperNotificationSeeMorePressed});

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _currentPasswordKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _newPasswordKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _confirmPasswordKey = GlobalKey<FormState>();
  final GlobalKey<LoadingButtonState> _loadingButtonKey =
      GlobalKey<LoadingButtonState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ChangeWalletPasswordBloc, ChangeWalletPasswordState>(
        listener: (BuildContext context, ChangeWalletPasswordState state) {
          if (state is ChangeWalletPasswordLoading) {
            _loadingButtonKey.currentState?.animateForward();
          } else {
            _loadingButtonKey.currentState?.animateReverse();
          }
          if (state is ChangeWalletPasswordSuccess) {
            Navigator.pop(context);
          }
        },
        builder: (BuildContext context, ChangeWalletPasswordState state) {
          final String? currentPassErrorText =
              state is ChangeWalletPasswordIncorrectCurrentPassword
              ? context.l10n.incorrectPassword
              : null;
          final bool canSubmit = _arePasswordsValid(currentPassErrorText);

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                NotificationWidget(
                  onSeeMorePressed: widget._onStepperNotificationSeeMorePressed,
                ),
                Text(
                  context.l10n.changeWalletPassword,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                _buildPasswordFields(
                  context: context,
                  currentPassErrorText: currentPassErrorText,
                  canSubmit: canSubmit,
                ),
                DottedBorderInfoWidget(
                  text: context.l10n.passwordRequirementsInfo,
                ),
                _buildActionButtons(context: context, canSubmit: canSubmit),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordFields({
    required BuildContext context,
    required String? currentPassErrorText,
    required bool canSubmit,
  }) {
    return Column(
      children: <Widget>[
        Form(
          key: _currentPasswordKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: PasswordInputField(
            errorText: currentPassErrorText,
            controller: _currentPasswordController,
            hintText: context.l10n.currentPassword,
            onChanged: (String value) {
              if (currentPassErrorText != null) {
                context.read<ChangeWalletPasswordBloc>().add(
                  const ChangeWalletPasswordErrorCleared(),
                );
              }
              setState(() {});
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
            hintText: context.l10n.newPassword,
          ),
        ),
        kVerticalSpacing,
        Form(
          key: _confirmPasswordKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: PasswordInputField(
            controller: _confirmPasswordController,
            validator: (String? value) => InputValidators.checkPasswordMatch(
              _newPasswordController.text,
              value,
            ),
            hintText: context.l10n.repeatNewPassword,
            onSubmitted: (String value) {
              if (canSubmit) {
                _submit(context);
              }
            },
            onChanged: (String value) {
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 35),
        PasswordProgressBar(
          password: _newPasswordController.text,
          passwordKey: _newPasswordKey,
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required bool canSubmit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OnboardingButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          text: context.l10n.goBack,
        ),
        kSpacingBetweenActionButtons,
        LoadingButton.onboarding(
          key: _loadingButtonKey,
          onPressed: canSubmit ? () => _submit(context) : null,
          text: context.l10n.changePassword,
        ),
      ],
    );
  }

  bool _arePasswordsValid(String? currentPassErrorText) {
    return currentPassErrorText == null &&
        _currentPasswordController.text.isNotEmpty &&
        InputValidators.validatePassword(_newPasswordController.text) == null &&
        InputValidators.checkPasswordMatch(
              _newPasswordController.text,
              _confirmPasswordController.text,
            ) ==
            null;
  }

  void _submit(BuildContext context) {
    context.read<ChangeWalletPasswordBloc>().add(
      ChangeWalletPasswordSubmitted(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        decryptErrorTitle: context.l10n.errorDecryptingWallet,
        changePasswordErrorTitle: context.l10n.errorChangingPassword,
      ),
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
