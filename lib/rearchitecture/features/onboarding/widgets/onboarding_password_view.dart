import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Shared password creation form used by new, import, and hardware wallet
/// onboarding password screens.
class OnboardingPasswordView extends StatefulWidget {
  /// Creates an [OnboardingPasswordView].
  const OnboardingPasswordView({
    required this._currentLevel,
    required this._numLevels,
    required this._onConfirmed,
    this._headerSpacing = 65,
    this._progressBarSpacing = 35,
    this._popResult,
    super.key,
  });

  final int _currentLevel;
  final int _numLevels;
  final void Function(String password) _onConfirmed;
  final double _headerSpacing;
  final double _progressBarSpacing;
  final Object? _popResult;

  @override
  State<OnboardingPasswordView> createState() => _OnboardingPasswordViewState();
}

class _OnboardingPasswordViewState extends State<OnboardingPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _passwordKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _confirmPasswordKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: <Widget>[
                ProgressBar(
                  currentLevel: widget._currentLevel,
                  numLevels: widget._numLevels,
                ),
                const SizedBox(height: 30),
                Text(
                  context.l10n.createWalletPassword,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Text(
                  context.l10n.passwordRequiredToUnlockWallet,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: widget._headerSpacing),
                _buildPasswordFields(context),
              ],
            ),
            DottedBorderInfoWidget(
              text: context.l10n.useStrongPasswordRequirements,
            ),
            _buildActionRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordFields(BuildContext context) {
    return Column(
      children: <Widget>[
        Form(
          key: _passwordKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: PasswordInputField(
            hintText: context.l10n.password,
            controller: _passwordController,
            validator: InputValidators.validatePassword,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submitIfValid(),
          ),
        ),
        kVerticalSpacing,
        Form(
          key: _confirmPasswordKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: PasswordInputField(
            hintText: context.l10n.confirmPassword,
            controller: _confirmPasswordController,
            validator: (String? value) => InputValidators.checkPasswordMatch(
              _passwordController.text,
              value,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submitIfValid(),
          ),
        ),
        SizedBox(height: widget._progressBarSpacing),
        PasswordProgressBar(
          password: _passwordController.text,
          passwordKey: _passwordKey,
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildGoBackButton(context),
        kSpacingBetweenActionButtons,
        _buildConfirmButton(context),
      ],
    );
  }

  Widget _buildGoBackButton(BuildContext context) {
    return OnboardingButton(
      onPressed: () {
        if (widget._popResult != null) {
          Navigator.pop(context, widget._popResult);
        } else {
          Navigator.pop(context);
        }
      },
      text: context.l10n.goBack,
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return OnboardingButton(
      onPressed: _arePasswordsValid() ? _submitIfValid : null,
      text: context.l10n.confirmPassword,
    );
  }

  void _submitIfValid() {
    if (_arePasswordsValid()) {
      widget._onConfirmed(_passwordController.text);
    }
  }

  bool _arePasswordsValid() {
    return InputValidators.validatePassword(_passwordController.text) == null &&
        InputValidators.checkPasswordMatch(
              _passwordController.text,
              _confirmPasswordController.text,
            ) ==
            null;
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
