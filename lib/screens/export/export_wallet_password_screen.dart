import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ExportWalletPasswordScreen extends StatefulWidget {

  const ExportWalletPasswordScreen(
    this.seed, {
    this.backupWalletFlow = false,
    super.key,
  });
  final String seed;
  final bool backupWalletFlow;

  @override
  State<ExportWalletPasswordScreen> createState() =>
      _ExportWalletPasswordScreenState();
}

class _ExportWalletPasswordScreenState
    extends State<ExportWalletPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _passwordKey = GlobalKey();
  final GlobalKey<FormState> _confirmPasswordKey = GlobalKey();

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
            Column(
              children: [
                const ProgressBar(
                  currentLevel: 2,
                  numLevels: 2,
                ),
                kVerticalSpacing,
                Container(
                  color: Colors.transparent,
                  child: SvgPicture.asset(
                    'assets/svg/ic_export_seed.svg',
                    colorFilter: const ColorFilter.mode(
                        AppColors.znnColor, BlendMode.srcIn,),
                    height: 55,
                  ),
                ),
                kVerticalSpacing,
                Text(
                  'Export Seed Vault',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Text(
                  'Please enter a strong Seed Vault Key to encrypt your Seed',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 50,
                ),
                Column(
                  children: [
                    Form(
                      key: _passwordKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: PasswordInputField(
                        hintText: 'Password',
                        controller: _passwordController,
                        validator: InputValidators.validatePassword,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    kVerticalSpacing,
                    Form(
                      key: _confirmPasswordKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: PasswordInputField(
                        hintText: 'Confirm password',
                        controller: _confirmPasswordController,
                        validator: (value) =>
                            InputValidators.checkPasswordMatch(
                          _passwordController.text,
                          value,
                        ),
                        onChanged: (value) {
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
            ),
            const DottedBorderInfoWidget(
              text: 'Store your Seed Vault and Seed Vault Key in secure and '
                  'separate offline locations. You will need both to '
                  'access your funds',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _getGoBackButton(),
                kSpacingBetweenActionButtons,
                _getExportButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getExportButton() {
    return OnboardingButton(
      onPressed: _arePasswordsValid()
          ? () async {
              String? initialDirectory;
              if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
                initialDirectory =
                    (await getApplicationDocumentsDirectory()).path;
              }
              final walletPath = await getSaveLocation(
                acceptedTypeGroups: <XTypeGroup>[
                  const XTypeGroup(
                    label: 'file',
                    extensions: <String>['json'],
                  ),
                ],
                initialDirectory: initialDirectory,
                suggestedName:
                    'zenon-syrius-wallet-backup-${FormatUtils.formatDate(
                  DateTime.now().millisecondsSinceEpoch,
                  dateFormat: 'yyyy-MM-dd-HHmm',
                )}.json',
              );
              if (walletPath != null) {
                final keyStoreManager = KeyStoreManager(
                  walletPath: Directory(
                    path.dirname(walletPath.path),
                  ),
                );
                final keyStore = KeyStore.fromMnemonic(widget.seed);
                await keyStoreManager.saveKeyStore(
                  keyStore,
                  _passwordController.text,
                  name: path.basename(walletPath.path),
                );
                if (widget.backupWalletFlow) {
                  await _sendSuccessNotification(walletPath.path);
                } else {
                  _updateExportedSeedList();
                }
                if (!mounted) return;
                NavigationUtils.popRepeated(context, 2);
              }
            }
          : null,
      text: 'Export',
    );
  }

  void _updateExportedSeedList() {
    final exportedSeeds = <String>[];
    exportedSeeds.addAll(Provider.of<ValueNotifier<List<String>>>(
      context,
      listen: false,
    ).value,);
    exportedSeeds.add(widget.seed);
    Provider.of<ValueNotifier<List<String>>>(
      context,
      listen: false,
    ).value = exportedSeeds;
  }

  Future<void> _sendSuccessNotification(String path) async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Seed Vault successfully exported',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'The Seed Vault was successfully exported to $path',
            type: NotificationType.paymentSent,
          ),
        );
  }

  Widget _getGoBackButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      text: 'Go back',
    );
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
