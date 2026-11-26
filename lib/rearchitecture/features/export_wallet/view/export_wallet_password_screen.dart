import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/export_wallet/bloc/export_wallet_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Step 2 of the Seed Vault export flow where the user enters an encryption
/// password and saves the encrypted JSON backup file.
class ExportWalletPasswordScreen extends StatelessWidget {
  /// Creates an [ExportWalletPasswordScreen].
  const ExportWalletPasswordScreen(
    this._seed, {
    this._backupWalletFlow = false,
    this._bloc,
    super.key,
  });

  final String _seed;
  final bool _backupWalletFlow;
  final ExportWalletBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final ExportWalletBloc? injected = _bloc;
    final Widget view = _View(seed: _seed, backupWalletFlow: _backupWalletFlow);
    if (injected != null) {
      return BlocProvider<ExportWalletBloc>.value(value: injected, child: view);
    }

    return BlocProvider<ExportWalletBloc>(
      create: (_) => ExportWalletBloc(),
      child: view,
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this._seed, required this._backupWalletFlow});

  final String _seed;
  final bool _backupWalletFlow;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _passwordKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _confirmPasswordKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ExportWalletBloc, ExportWalletState>(
        listener: (BuildContext context, ExportWalletState state) {
          if (state is ExportWalletSuccess) {
            if (!state.backupWalletFlow) {
              _updateExportedSeedList(context);
            }
            NavigationUtils.popRepeated(context, 2);
          }
        },
        builder: (BuildContext context, ExportWalletState state) {
          final bool isLoading = state is ExportWalletLoading;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildHeaderAndForm(context),
                DottedBorderInfoWidget(
                  text: context.l10n.storeSeedVaultOfflineLocations,
                ),
                _buildActionButtons(context, isLoading: isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderAndForm(BuildContext context) {
    return Column(
      children: <Widget>[
        const ProgressBar(currentLevel: 2, numLevels: 2),
        kVerticalSpacing,
        SvgPicture.asset(
          'assets/svg/ic_export_seed.svg',
          colorFilter: const ColorFilter.mode(
            AppColors.znnColor,
            BlendMode.srcIn,
          ),
          height: 55,
        ),
        kVerticalSpacing,
        Text(
          context.l10n.exportSeedVault,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        kVerticalSpacing,
        Text(
          context.l10n.enterStrongSeedVaultKey,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 50),
        Column(
          children: <Widget>[
            Form(
              key: _passwordKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: PasswordInputField(
                hintText: context.l10n.password,
                controller: _passwordController,
                validator: (String? value) =>
                    InputValidators.validatePassword(value, l10n: context.l10n),
                onChanged: (String value) {
                  setState(() {});
                },
              ),
            ),
            kVerticalSpacing,
            Form(
              key: _confirmPasswordKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: PasswordInputField(
                hintText: context.l10n.confirmPassword,
                controller: _confirmPasswordController,
                validator: (String? value) =>
                    InputValidators.checkPasswordMatch(
                      _passwordController.text,
                      value,
                      l10n: context.l10n,
                    ),
                onChanged: (String value) {
                  setState(() {});
                },
              ),
            ),
            kVerticalSpacing,
            PasswordProgressBar(
              password: _passwordController.text,
              passwordKey: _passwordKey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, {required bool isLoading}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OnboardingButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          text: context.l10n.goBack,
        ),
        kSpacingBetweenActionButtons,
        OnboardingButton(
          onPressed: !isLoading && _arePasswordsValid()
              ? () {
                  context.read<ExportWalletBloc>().add(
                    ExportWalletRequested(
                      seed: widget._seed,
                      password: _passwordController.text,
                      backupWalletFlow: widget._backupWalletFlow,
                      successTitle: context.l10n.seedVaultExported,
                      successDetailsBuilder:
                          context.l10n.seedVaultExportedToPath,
                      errorTitle: context.l10n.errorExportingSeedVault,
                    ),
                  );
                }
              : null,
          text: context.l10n.export,
        ),
      ],
    );
  }

  void _updateExportedSeedList(BuildContext context) {
    final ValueNotifier<List<String>> notifier =
        Provider.of<ValueNotifier<List<String>>>(context, listen: false);
    notifier.value = <String>[...notifier.value, widget._seed];
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
