import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Full-window lock screen matching mockups Screens 41–43.
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

  List<String> _discoverWallets() {
    try {
      final Directory dir = znnDefaultWalletDirectory;
      if (!dir.existsSync()) {
        return const <String>[];
      }
      return dir.listSync().whereType<File>().map((File f) => f.path).toList()
        ..sort();
    } on Object catch (_) {
      return const <String>[];
    }
  }

  String _currentWalletLabel() {
    final String? path = kWalletPath;
    if (path != null && path.isNotEmpty) {
      return p.basenameWithoutExtension(path);
    }
    return 'Main';
  }

  String _shortSelectedAddress() {
    final String? addr = kSelectedAddress;
    if (addr == null || addr.length < 14) {
      return '';
    }
    return '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final List<String> walletFiles = _discoverWallets();

    return BlocConsumer<WalletUnlockBloc, WalletUnlockState>(
      listener: _onUnlockStateChanged,
      builder: (BuildContext context, WalletUnlockState state) {
        final bool isInitializing =
            state.status == WalletUnlockStatus.initializing;
        final bool hasError = state.status == WalletUnlockStatus.failure;

        return SyriusAmbientBackdrop(
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
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SyriusCard(
                      borderRadius: 14,
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildBrandBanner(tokens, hasError: hasError),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Text(
                                    context.l10n.welcomeBack,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    context.l10n.enterPasswordToAccessWallet,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.l10n.wallet.toUpperCase(),
                                    style: tokens.microLabelStyle(),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildWalletSelector(
                                    context,
                                    tokens,
                                    walletFiles,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.l10n.password.toUpperCase(),
                                    style: tokens.microLabelStyle(),
                                  ),
                                  const SizedBox(height: 6),
                                  PasswordInputField(
                                    key: const Key('wallet_password_field'),
                                    controller: _passwordController,
                                    hintText: context.l10n.password,
                                    onSubmitted: (_) =>
                                        _onSubmitPressed(context, state),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStatusMessage(
                                    context,
                                    tokens,
                                    isInitializing: isInitializing,
                                    hasError: hasError,
                                    remainingAttempts: state.remainingAttempts,
                                  ),
                                  const SizedBox(height: 16),
                                  SyriusGradientButton(
                                    key: const Key('wallet_unlock_button'),
                                    label: context.l10n.unlock,
                                    icon: Icons.lock_open_rounded,
                                    height: 44,
                                    isLoading: state.isBusy,
                                    onPressed: state.isBusy
                                        ? null
                                        : () =>
                                              _onSubmitPressed(context, state),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: <Widget>[
                                      Flexible(
                                        child: SyriusGhostButton(
                                          label: context.l10n.addAWallet,
                                          onPressed: () {
                                            NavigationUtils.push(
                                              context,
                                              const AccessWalletScreen(),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: SyriusGhostButton(
                                            label: context
                                                .l10n
                                                .forgotThePassword,
                                            onPressed: () {
                                              NavigationUtils.push(
                                                context,
                                                const ResetWalletScreen(),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _buildFooterStrip(context, tokens),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandBanner(SyriusThemeTokens tokens, {required bool hasError}) {
    return Container(
      height: 108,
      color: Colors.black,
      alignment: Alignment.center,
      child: hasError
          ? Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tokens.znnGreen.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'ZN',
                style: tokens.monoStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tokens.znnGreen,
                ),
              ),
            )
          : const Text(
              'S  Y  R  I  U  S',
              style: TextStyle(
                fontSize: 19,
                letterSpacing: 7,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
    );
  }

  Widget _buildWalletSelector(
    BuildContext context,
    SyriusThemeTokens tokens,
    List<String> walletFiles,
  ) {
    final String walletLabel = _currentWalletLabel();
    final String shortAddr = _shortSelectedAddress();

    return PopupMenuButton<String>(
      onSelected: (String value) {
        if (value == '__add__') {
          NavigationUtils.push(context, const AccessWalletScreen());
        } else {
          kWalletPath = value;
          setState(() {});
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final String path in walletFiles)
          PopupMenuItem<String>(
            value: path,
            child: Text(p.basenameWithoutExtension(path)),
          ),
        if (walletFiles.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '__add__',
          child: Row(
            children: <Widget>[
              Icon(Icons.add, size: 15, color: tokens.znnGreen),
              const SizedBox(width: 8),
              Text(context.l10n.addAWallet),
            ],
          ),
        ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.key_rounded, size: 15, color: tokens.textMuted),
            const SizedBox(width: 8),
            Text(
              walletLabel,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: tokens.textPrimary,
              ),
            ),
            if (shortAddr.isNotEmpty) ...<Widget>[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shortAddr,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.monoStyle(
                    fontSize: 12,
                    color: tokens.textMuted,
                  ),
                ),
              ),
            ] else
              const Spacer(),
            Icon(Icons.keyboard_arrow_down, size: 16, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required bool isInitializing,
    required bool hasError,
    required int remainingAttempts,
  }) {
    if (isInitializing) {
      return Text(
        context.l10n.initializingWalletPleaseWait,
        style: TextStyle(fontSize: 12.5, color: tokens.znnGreen),
      );
    }

    final String message = remainingAttempts == 1
        ? context.l10n.lastAttemptWalletWillReset
        : context.l10n.attemptsLeft(remainingAttempts);

    if (hasError || remainingAttempts == 1) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, size: 15, color: tokens.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: tokens.error, height: 1.35),
            ),
          ),
        ],
      );
    }

    return Text(
      message,
      style: TextStyle(fontSize: 12, color: tokens.textMuted),
    );
  }

  Widget _buildFooterStrip(BuildContext context, SyriusThemeTokens tokens) {
    final String nodeLabel =
        kCurrentNode == kEmbeddedNode || kCurrentNode == null
        ? context.l10n.embeddedNode
        : kCurrentNode!;
    return SyriusCard(
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: tokens.znnGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            nodeLabel,
            style: tokens.monoStyle(
              fontSize: 11.5,
              color: tokens.textSecondary,
            ),
          ),
          const Spacer(),
          SyriusGhostButton(
            label: context.l10n.whatChanged,
            onPressed: () =>
                unawaited(NavigationUtils.openUrl(kGithubReleasesLink)),
          ),
        ],
      ),
    );
  }

  void _onSubmitPressed(BuildContext context, WalletUnlockState state) {
    if (_passwordController.text.isEmpty || state.isBusy) {
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
      case WalletUnlockStatus.success:
        _passwordController.clear();
      case WalletUnlockStatus.autoEraseTriggered:
        NavigationUtils.pushReplacement(
          context,
          const SplashScreen(resetWalletFlow: true),
        );
      case WalletUnlockStatus.initial:
      case WalletUnlockStatus.decrypting:
      case WalletUnlockStatus.initializing:
      case WalletUnlockStatus.failure:
        break;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
