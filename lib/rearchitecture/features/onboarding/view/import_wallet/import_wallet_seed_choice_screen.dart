import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Redesigned wallet import screen matching mockup Screen 45.
class ImportWalletSeedChoiceScreen extends StatelessWidget {
  /// Creates an [ImportWalletSeedChoiceScreen].
  const ImportWalletSeedChoiceScreen({this._clearAddressesBox, super.key});

  final Future<void> Function()? _clearAddressesBox;

  @override
  Widget build(BuildContext context) {
    return _View(
      clearAddressesBox: _clearAddressesBox ?? _defaultClearAddressesBox,
    );
  }

  static Future<void> _defaultClearAddressesBox() async {
    final bool addressesBoxExists = await Hive.boxExists(kAddressesBox);
    if (addressesBoxExists) {
      final Box<dynamic> addressesBox = await Hive.openBox<dynamic>(
        kAddressesBox,
      );
      await addressesBox.clear();
    }
  }
}

class _View extends StatefulWidget {
  const _View({required this._clearAddressesBox});

  final Future<void> Function() _clearAddressesBox;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  bool _isSeed12Selected = true;
  String? _walletFilePath;
  final TextEditingController _seedController = TextEditingController();

  int get _expectedWordCount => _isSeed12Selected ? 12 : 24;

  List<String> get _enteredWords => _seedController.text
      .trim()
      .split(RegExp(r'\s+'))
      .where((String w) => w.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    unawaited(_clearCachedAddresses());
  }

  Future<void> _clearCachedAddresses() async {
    try {
      await widget._clearAddressesBox();
    } on Object catch (error, stackTrace) {
      Logger(
        'ImportWalletSeedChoiceScreen',
      ).log(Level.WARNING, '_clearCachedAddresses', error, stackTrace);
    }
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final List<String> words = _enteredWords;
    final bool hasFullSeed = words.length == _expectedWordCount;
    final bool canContinue = hasFullSeed || _walletFilePath != null;

    return Scaffold(
      body: SyriusAmbientBackdrop(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 16,
              left: 18,
              child: Text(
                'S Y R I U S',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3.5,
                  color: tokens.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SyriusCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            SyriusGhostButton(
                              label: context.l10n.back,
                              icon: Icons.chevron_left,
                              onPressed: () {
                                Navigator.popUntil(
                                  context,
                                  ModalRoute.withName(AccessWalletScreen.route),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n.importYourWallet,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SyriusHorizontalStepper(
                          steps: <String>[
                            context.l10n.seedOrFile,
                            context.l10n.password,
                            context.l10n.ready,
                          ],
                          currentStep: 0,
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: tokens.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tokens.borderStrong),
                          ),
                          child: SelectFileWidget(
                            fileExtension: 'json',
                            onPathFoundCallback: (String path) {
                              setState(() {
                                _walletFilePath = path;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Stack(
                          children: <Widget>[
                            TextField(
                              controller: _seedController,
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                              style: tokens.monoStyle(
                                color: tokens.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    context.l10n.inputSeedOrImportSeedVault,
                                contentPadding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  30,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 8,
                              child: Text(
                                '${words.length} of $_expectedWordCount',
                                style: tokens.monoStyle(
                                  fontSize: 11.5,
                                  color: hasFullSeed
                                      ? tokens.znnGreen
                                      : tokens.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: <Widget>[
                            SyriusSegmentedControl<bool>(
                              selected: _isSeed12Selected,
                              onChanged: (bool is12) {
                                setState(() => _isSeed12Selected = is12);
                              },
                              options: const <SyriusSegmentOption<bool>>[
                                SyriusSegmentOption<bool>(
                                  value: true,
                                  label: '12 words',
                                ),
                                SyriusSegmentOption<bool>(
                                  value: false,
                                  label: '24 words',
                                ),
                              ],
                            ),
                            const Spacer(),
                            OnboardingButton(
                              onPressed: canContinue
                                  ? () => _onContinuePressed(context)
                                  : null,
                              text: context.l10n.continueText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinuePressed(BuildContext context) {
    if (_walletFilePath != null) {
      NavigationUtils.push(
        context,
        ImportWalletDecryptScreen(_walletFilePath!),
      );
      return;
    }

    final List<String> words = _enteredWords;
    if (Mnemonic.validateMnemonic(words)) {
      NavigationUtils.push(
        context,
        ImportWalletPasswordScreen(words.join(' '), progressBarNumLevels: 4),
      );
    } else {
      unawaited(
        showSyriusBlurredDialog<void>(
          context: context,
          maxWidth: 400,
          builder: (BuildContext dialogContext) => SyriusModalShell(
            title: context.l10n.importingSeed,
            actions: <Widget>[
              SyriusGradientButton(
                label: context.l10n.ok,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
            child: Text(context.l10n.mnemonicIsNotValid),
          ),
        ),
      );
    }
  }
}
