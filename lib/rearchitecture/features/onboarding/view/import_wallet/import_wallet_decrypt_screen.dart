import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Screen prompting for the Seed Vault Key to decrypt an imported keystore.
class ImportWalletDecryptScreen extends StatelessWidget {
  /// Creates an [ImportWalletDecryptScreen].
  const ImportWalletDecryptScreen(this._path, {this._decryptBloc, super.key});

  final String _path;
  final DecryptWalletFileBloc? _decryptBloc;

  @override
  Widget build(BuildContext context) {
    final Widget view = _View(path: _path);
    final DecryptWalletFileBloc? injectedBloc = _decryptBloc;
    if (injectedBloc != null) {
      return BlocProvider<DecryptWalletFileBloc>.value(
        value: injectedBloc,
        child: view,
      );
    }

    return BlocProvider<DecryptWalletFileBloc>(
      create: (_) => DecryptWalletFileBloc(),
      child: view,
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this._path});

  final String _path;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  String? _passwordErrorText;

  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<LoadingButtonState> _loadingButtonKey =
      GlobalKey<LoadingButtonState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<DecryptWalletFileBloc, DecryptWalletFileState>(
        listener: _onDecryptStateChanged,
        builder: (BuildContext context, DecryptWalletFileState state) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildHeader(context),
                PasswordInputField(
                  hintText: context.l10n.password,
                  controller: _passwordController,
                  onChanged: (_) => setState(() {}),
                  errorText: _passwordErrorText,
                  onSubmitted: (_) => _onSubmitPressed(context, state),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildGoBackButton(context),
                    kSpacingBetweenActionButtons,
                    _buildContinueButton(context, state),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: <Widget>[
        const ProgressBar(currentLevel: 2),
        const SizedBox(height: 30),
        Text(
          context.l10n.unlockYourSeedVault,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        kVerticalSpacing,
        Text(
          context.l10n.inputSeedVaultKeyToContinue,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildGoBackButton(BuildContext context) {
    return OnboardingButton(
      onPressed: () => Navigator.pop(context),
      text: context.l10n.goBack,
    );
  }

  Widget _buildContinueButton(
    BuildContext context,
    DecryptWalletFileState state,
  ) {
    return LoadingButton.onboarding(
      key: _loadingButtonKey,
      onPressed: _passwordController.text.isNotEmpty
          ? () => _onSubmitPressed(context, state)
          : null,
      text: context.l10n.continueText,
    );
  }

  void _onSubmitPressed(BuildContext context, DecryptWalletFileState state) {
    if (_passwordController.text.isEmpty ||
        state is DecryptWalletFileLoading ||
        _loadingButtonKey.currentState?.btnState == ButtonState.busy) {
      return;
    }

    context.read<DecryptWalletFileBloc>().add(
      DecryptWalletFileRequested(
        path: widget._path,
        password: _passwordController.text,
      ),
    );
  }

  void _onDecryptStateChanged(
    BuildContext context,
    DecryptWalletFileState state,
  ) {
    switch (state) {
      case DecryptWalletFileLoading():
        _loadingButtonKey.currentState?.animateForward();
      case DecryptWalletFileSuccess(:final WalletFile walletFile):
        unawaited(_handleDecryptedWallet(context, walletFile));
      case DecryptWalletFileFailure(
        :final Object error,
        :final bool isIncorrectPassword,
      ):
        _loadingButtonKey.currentState?.animateReverse();
        setState(() {
          _passwordErrorText = isIncorrectPassword
              ? context.l10n.incorrectPassword
              : error is FormatException
              ? context.l10n.notAValidKeystoreFile
              : error.toString();
        });
      case DecryptWalletFileInitial():
        break;
    }
  }

  Future<void> _handleDecryptedWallet(
    BuildContext context,
    WalletFile walletFile,
  ) async {
    String? mnemonic;
    try {
      if (walletFile is! KeyStoreWalletFile) {
        _loadingButtonKey.currentState?.animateReverse();
        if (!mounted) {
          return;
        }
        setState(() {
          _passwordErrorText = context.l10n.unsupportedWalletFileType;
        });
        return;
      }

      mnemonic = await walletFile.access<String>(
        (Wallet wallet) => Future<String>.value((wallet as KeyStore).mnemonic!),
      );
    } on Object catch (error) {
      _loadingButtonKey.currentState?.animateReverse();
      if (!mounted) {
        return;
      }
      setState(() {
        _passwordErrorText = error.toString();
      });
      return;
    } finally {
      try {
        await walletFile.close();
      } on Object catch (_) {
        // Best-effort cleanup of the temporary decrypted keystore handle.
      }
    }

    _loadingButtonKey.currentState?.animateReverse();
    if (!context.mounted) {
      return;
    }
    setState(() {
      _passwordErrorText = null;
    });
    NavigationUtils.push(context, ImportWalletPasswordScreen(mnemonic));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
