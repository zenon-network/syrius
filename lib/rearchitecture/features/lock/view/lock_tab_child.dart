import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Lock screen tab requiring the wallet password before accessing the wallet.
class LockTabChild extends StatelessWidget {
  /// Creates a [LockTabChild].
  const LockTabChild(
    this._afterUnlockCallback,
    this._afterInitCallback, {
    this._unlockBloc,
    super.key,
  });

  final Future<void> Function(String) _afterUnlockCallback;
  final void Function() _afterInitCallback;
  final WalletUnlockBloc? _unlockBloc;

  @override
  Widget build(BuildContext context) {
    final WalletUnlockBloc? injectedBloc = _unlockBloc;
    if (injectedBloc != null) {
      return BlocProvider<WalletUnlockBloc>.value(
        value: injectedBloc,
        child: const _View(),
      );
    }

    return BlocProvider<WalletUnlockBloc>(
      create: (_) => WalletUnlockBloc(
        afterUnlockCallback: _afterUnlockCallback,
        afterInitCallback: _afterInitCallback,
      ),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<LoadingButtonState> _actionButtonKey =
      GlobalKey<LoadingButtonState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletUnlockBloc, WalletUnlockState>(
      listener: _onUnlockStateChanged,
      builder: (BuildContext context, WalletUnlockState state) {
        final bool isInitializing =
            state.status == WalletUnlockStatus.initializing;

        return ColoredBox(
          color: Theme.of(context).colorScheme.primary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Fontisto.locked, color: AppColors.znnColor, size: 50),
              const SizedBox(height: 40),
              Text(
                context.l10n.welcomeBack,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.enterPasswordToAccessWallet,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 40),
              _buildPasswordRow(context, state),
              const SizedBox(height: 30),
              _buildStatusMessage(
                context,
                isInitializing: isInitializing,
                remainingAttempts: state.remainingAttempts,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPasswordRow(BuildContext context, WalletUnlockState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        PasswordInputField(
          key: const Key('wallet_password_field'),
          controller: _passwordController,
          hintText: context.l10n.currentPassword,
          onSubmitted: (_) => _onSubmitPressed(context, state),
        ),
        const SizedBox(width: 10),
        KeyedSubtree(
          key: const Key('wallet_unlock_button'),
          child: _buildActionButton(context, state),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, WalletUnlockState state) {
    return LoadingButton(
      onPressed: () => _onSubmitPressed(context, state),
      key: _actionButtonKey,
      minimumSize: const Size(50, 50),
      child: const Icon(
        Icons.keyboard_arrow_right,
        color: AppColors.znnColor,
        size: 25,
      ),
    );
  }

  Widget _buildStatusMessage(
    BuildContext context, {
    required bool isInitializing,
    required int remainingAttempts,
  }) {
    if (isInitializing) {
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Text(
          context.l10n.initializingWalletPleaseWait,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Text(
      remainingAttempts == 1
          ? context.l10n.lastAttemptWalletWillReset
          : context.l10n.attemptsLeft(remainingAttempts),
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  void _onSubmitPressed(BuildContext context, WalletUnlockState state) {
    if (_passwordController.text.isEmpty ||
        state.isBusy ||
        _actionButtonKey.currentState?.btnState == ButtonState.busy) {
      return;
    }

    context.read<WalletUnlockBloc>().add(
      WalletUnlockSubmitted(
        password: _passwordController.text,
        incorrectPasswordTitle: context.l10n.incorrectPassword,
        unlockFailedTitle: context.l10n.unlockFailed,
        ledgerErrorTitleBuilder: context.l10n.ledgerWithDetails,
      ),
    );
  }

  void _onUnlockStateChanged(BuildContext context, WalletUnlockState state) {
    switch (state.status) {
      case WalletUnlockStatus.decrypting:
        _actionButtonKey.currentState?.animateForward();
      case WalletUnlockStatus.success:
        _passwordController.clear();
        _actionButtonKey.currentState?.animateReverse();
      case WalletUnlockStatus.failure:
        _actionButtonKey.currentState?.animateReverse();
      case WalletUnlockStatus.autoEraseTriggered:
        _actionButtonKey.currentState?.animateReverse();
        NavigationUtils.pushReplacement(
          context,
          const SplashScreen(resetWalletFlow: true),
        );
      case WalletUnlockStatus.initial:
      case WalletUnlockStatus.initializing:
        break;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
