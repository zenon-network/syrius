import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/dump_mnemonic/dump_mnemonic.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Prompts for the wallet password and reveals the mnemonic phrase on screen.
class DumpMnemonicScreen extends StatelessWidget {
  /// Creates a [DumpMnemonicScreen].
  const DumpMnemonicScreen({super.key, this._bloc});

  final DumpMnemonicBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final DumpMnemonicBloc? injected = _bloc;
    if (injected != null) {
      return BlocProvider<DumpMnemonicBloc>.value(
        value: injected,
        child: const _View(),
      );
    }

    return BlocProvider<DumpMnemonicBloc>(
      create: (_) => DumpMnemonicBloc(),
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
  final GlobalKey<LoadingButtonState> _continueButtonKey =
      GlobalKey<LoadingButtonState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<DumpMnemonicBloc, DumpMnemonicState>(
        listener: (BuildContext context, DumpMnemonicState state) {
          if (state is DumpMnemonicLoading) {
            _continueButtonKey.currentState?.animateForward();
          } else {
            _continueButtonKey.currentState?.animateReverse();
          }
          if (state is DumpMnemonicUnlocked) {
            _passwordController.clear();
          }
        },
        builder: (BuildContext context, DumpMnemonicState state) {
          final bool isLoading = state is DumpMnemonicLoading;
          final bool canSubmit =
              !isLoading && _passwordController.text.isNotEmpty;
          final List<String>? seedWords = state is DumpMnemonicUnlocked
              ? state.seedWords
              : null;
          final String? passwordError = switch (state) {
            DumpMnemonicIncorrectPassword() => context.l10n.incorrectPassword,
            DumpMnemonicFailure(:final String errorMessage) => errorMessage,
            _ => null,
          };

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Visibility(
                  visible: seedWords == null,
                  child: Text(
                    context.l10n.enterWalletPasswordToDumpMnemonic,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                Visibility(
                  visible: seedWords == null,
                  child: PasswordInputField(
                    controller: _passwordController,
                    hintText: context.l10n.currentPassword,
                    onSubmitted: (String value) {
                      if (canSubmit) {
                        _submit(context);
                      }
                    },
                    onChanged: (String value) {
                      if (passwordError != null) {
                        context.read<DumpMnemonicBloc>().add(
                          const DumpMnemonicErrorCleared(),
                        );
                      }
                      setState(() {});
                    },
                    errorText: passwordError,
                  ),
                ),
                if (seedWords != null)
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: SeedGrid(seedWords, enableSeedInputFields: false),
                    ),
                  ),
                _buildActionButtons(
                  context,
                  seedWords: seedWords,
                  canSubmit: canSubmit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required List<String>? seedWords,
    required bool canSubmit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OnboardingButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          text: seedWords != null ? context.l10n.lock : context.l10n.goBack,
        ),
        Visibility(
          visible: seedWords == null,
          child: Row(
            children: <Widget>[
              kSpacingBetweenActionButtons,
              LoadingButton.onboarding(
                onPressed: canSubmit ? () => _submit(context) : null,
                text: context.l10n.continueText,
                key: _continueButtonKey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    context.read<DumpMnemonicBloc>().add(
      DumpMnemonicSubmitted(password: _passwordController.text),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
