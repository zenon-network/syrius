import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Tab content rendering the unified Send / Receive / Zap experience and
/// pending receives card (Screens 07–12).
class TransferTabChild extends StatefulWidget {
  /// Creates a [TransferTabChild].
  const TransferTabChild({super.key});

  @override
  State<TransferTabChild> createState() => _TransferTabChildState();
}

class _TransferTabChildState extends State<TransferTabChild> {
  static final NumberFormat _amountFormat = NumberFormat('#,##0.####');

  TransferMode _mode = TransferMode.send;
  ShellNavigationController? _navController;
  int _lastHandledNonce = -1;

  // Send state
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _senderAddress = kSelectedAddress ?? '';
  Token _selectedToken = kZnnCoin;
  bool _lookalikeDismissed = false;
  bool _isSending = false;
  bool _sendDialogOpen = false;
  _PendingSendSummary? _pendingSendSummary;

  // Receive state
  bool _showQr = false;
  bool _showAmountRequest = false;
  final TextEditingController _receiveAmountController =
      TextEditingController();
  Token _receiveToken = kZnnCoin;

  // Zap state
  final TextEditingController _zapAddressController = TextEditingController();
  final TextEditingController _zapZnnController = TextEditingController(
    text: '1',
  );
  final TextEditingController _zapQsrController = TextEditingController(
    text: '10',
  );
  final TextEditingController _zapMessageController = TextEditingController();
  bool _isZapping = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_senderAddress.isEmpty && kSelectedAddress != null) {
      _senderAddress = kSelectedAddress!;
    }
    final ShellNavigationController? nav =
        Provider.of<ShellNavigationController?>(context, listen: false);
    if (!identical(nav, _navController)) {
      _navController?.transferRequest.removeListener(_onTransferRequest);
      _navController = nav;
      _navController?.transferRequest.addListener(_onTransferRequest);
      _onTransferRequest();
    }
  }

  void _onTransferRequest() {
    final TransferNavigationRequest? req =
        _navController?.transferRequest.value;
    if (req == null || req.nonce == _lastHandledNonce) {
      return;
    }
    _lastHandledNonce = req.nonce;
    if (!mounted) {
      return;
    }
    setState(() {
      _mode = req.mode;
      if (req.recipientAddress != null && req.recipientAddress!.isNotEmpty) {
        if (req.mode == TransferMode.zap) {
          _zapAddressController.text = req.recipientAddress!;
        } else {
          _recipientController.text = req.recipientAddress!;
          _lookalikeDismissed = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _navController?.transferRequest.removeListener(_onTransferRequest);
    _recipientController.dispose();
    _amountController.dispose();
    _receiveAmountController.dispose();
    _zapAddressController.dispose();
    _zapZnnController.dispose();
    _zapQsrController.dispose();
    _zapMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final AppUiPreferencesNotifier uiPrefs = context
        .watch<AppUiPreferencesNotifier>();

    return BlocListener<SendTransactionBloc, SendTransactionState>(
      listenWhen: (SendTransactionState prev, SendTransactionState curr) =>
          prev.status != curr.status,
      listener: _onSendStateChanged,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildMainCard(context, tokens, uiPrefs),
                const SizedBox(height: 14),
                _buildToReceiveCard(context, tokens, uiPrefs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    return BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
      builder: (BuildContext context, MultipleBalanceState balState) {
        final Map<String, AccountInfo> balances =
            balState.data ?? const <String, AccountInfo>{};
        final String effectiveSender = balances.containsKey(_senderAddress)
            ? _senderAddress
            : (kSelectedAddress ??
                  (balances.keys.isNotEmpty ? balances.keys.first : ''));
        final AccountInfo? accountInfo = balances[effectiveSender];
        final List<Token> availableTokens = <Token>[...kDualCoin];
        if (accountInfo != null) {
          fillAvailableTokens(
            initialTokens: kDualCoin,
            list: availableTokens,
            tokensWithBalance: getTokensWithBalance(accountInfo: accountInfo),
          );
        }

        final NodeSyncStatusCubit? syncCubit = _tryReadSyncCubit(context);
        final SyncInfo? syncInfo = syncCubit?.state.data?.second;
        final int behind =
            syncInfo != null && syncInfo.targetHeight > syncInfo.currentHeight
            ? syncInfo.targetHeight - syncInfo.currentHeight
            : 0;
        final bool isBehind =
            syncInfo != null &&
            syncInfo.state == SyncState.syncing &&
            behind > 2;

        return SyriusCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_mode == TransferMode.send && isBehind)
                _buildBehindBanner(tokens, behind),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Row(
                  children: <Widget>[
                    SyriusSegmentedControl<TransferMode>(
                      selected: _mode,
                      onChanged: (TransferMode next) =>
                          setState(() => _mode = next),
                      options: <SyriusSegmentOption<TransferMode>>[
                        SyriusSegmentOption<TransferMode>(
                          value: TransferMode.send,
                          label: context.l10n.send,
                        ),
                        SyriusSegmentOption<TransferMode>(
                          value: TransferMode.receive,
                          label: context.l10n.receive,
                        ),
                        SyriusSegmentOption<TransferMode>(
                          value: TransferMode.zap,
                          label: context.l10n.zap,
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildAddressPillSelector(
                      context,
                      tokens,
                      effectiveSender,
                      accountInfo,
                      uiPrefs,
                    ),
                  ],
                ),
              ),
              const SyriusDivider(),
              Padding(
                padding: const EdgeInsets.all(18),
                child: switch (_mode) {
                  TransferMode.send => _buildSendBody(
                    context,
                    tokens,
                    uiPrefs,
                    effectiveSender: effectiveSender,
                    accountInfo: accountInfo,
                    availableTokens: availableTokens,
                    isNodeBehind: isBehind,
                  ),
                  TransferMode.receive => _buildReceiveBody(
                    context,
                    tokens,
                    effectiveSender: effectiveSender,
                    availableTokens: availableTokens,
                  ),
                  TransferMode.zap => _buildZapBody(
                    context,
                    tokens,
                    effectiveSender: effectiveSender,
                    accountInfo: accountInfo,
                  ),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBehindBanner(SyriusThemeTokens tokens, int behind) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.warningSurface,
        border: Border(bottom: BorderSide(color: tokens.warningBorder)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, size: 16, color: tokens.warning),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12.5, color: tokens.textPrimary),
                children: <InlineSpan>[
                  TextSpan(
                    text: 'Node is $behind momentums behind. ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: 'A send waits until it catches up.',
                    style: TextStyle(color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPillSelector(
    BuildContext context,
    SyriusThemeTokens tokens,
    String currentAddress,
    AccountInfo? info,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final List<String> addresses = kDefaultAddressList
        .whereType<String>()
        .toList();
    final String label = currentAddress.isNotEmpty
        ? ZenonAddressUtils.getLabel(currentAddress)
        : context.l10n.addressNumber(1);
    final String balSuffix = _mode == TransferMode.send && info != null
        ? ' · ${uiPrefs.hideBalances ? '••••' : _formatRaw(
              info.znn() ?? BigInt.zero,
              kZnnCoin.decimals,
            )} ZNN'
        : '';

    return PopupMenuButton<String>(
      color: tokens.surface,
      onSelected: (String value) {
        setState(() {
          _senderAddress = value;
          _selectedToken = kZnnCoin;
        });
      },
      itemBuilder: (_) => addresses.map((String addr) {
        return PopupMenuItem<String>(
          value: addr,
          child: Row(
            children: <Widget>[
              Text(
                ZenonAddressUtils.getLabel(addr),
                style: TextStyle(fontSize: 13, color: tokens.textPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                _shorten(addr),
                style: tokens.monoStyle(
                  fontSize: 11.5,
                  color: tokens.textMuted,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$label$balSuffix',
              style: tokens.monoStyle(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: tokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendBody(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs, {
    required String effectiveSender,
    required AccountInfo? accountInfo,
    required List<Token> availableTokens,
    required bool isNodeBehind,
  }) {
    final String recipient = _recipientController.text.trim();
    final String amountText = _amountController.text.trim();
    final BigInt available =
        accountInfo?.getBalance(_selectedToken.tokenStandard) ?? BigInt.zero;

    final String? recipientError = recipient.isNotEmpty
        ? InputValidators.checkAddress(recipient, l10n: context.l10n)
        : null;
    final String? amountError = amountText.isNotEmpty
        ? InputValidators.correctValue(
            amountText,
            available,
            _selectedToken.decimals,
            BigInt.zero,
            l10n: context.l10n,
          )
        : null;

    final _LookalikeMatch? lookalike = _lookalikeDismissed
        ? null
        : _detectLookalikeAddress(recipient, uiPrefs);

    final bool valid =
        recipient.isNotEmpty &&
        amountText.isNotEmpty &&
        recipientError == null &&
        amountError == null &&
        lookalike == null &&
        !isNodeBehind;

    final List<MapEntry<String, String>> recentEntries = _buildRecentRecipients(
      uiPrefs,
    );
    final String? knownLabel =
        uiPrefs.contactLabelFor(recipient) ??
        (kAddressLabelMap.containsKey(recipient)
            ? kAddressLabelMap[recipient]
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: const Key('send_recipient_field'),
          controller: _recipientController,
          onChanged: (_) => setState(() => _lookalikeDismissed = false),
          style: tokens.monoStyle(fontSize: 13.5, color: tokens.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: tokens.surfaceSubtle,
            hintText: context.l10n.recipientAddress,
            errorText: recipientError,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: lookalike != null ? tokens.warning : tokens.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: lookalike != null ? tokens.warning : tokens.borderStrong,
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  iconSize: 16,
                  tooltip: context.l10n.pasteFromClipboard,
                  color: tokens.textMuted,
                  onPressed: () async {
                    final ClipboardData? clip = await Clipboard.getData(
                      Clipboard.kTextPlain,
                    );
                    if (clip?.text != null && mounted) {
                      setState(() {
                        _recipientController.text = clip!.text!.trim();
                        _lookalikeDismissed = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.content_paste_rounded),
                ),
                if (recipient.isNotEmpty)
                  IconButton(
                    iconSize: 16,
                    color: tokens.textMuted,
                    onPressed: () => setState(() {
                      _recipientController.clear();
                      _lookalikeDismissed = false;
                    }),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
        ),
        if (lookalike != null) ...<Widget>[
          const SizedBox(height: 12),
          _buildLookalikeWarning(context, tokens, lookalike, recipient),
        ] else if (recentEntries.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                context.l10n.recent,
                style: TextStyle(fontSize: 12, color: tokens.textMuted),
              ),
              ...recentEntries.map((MapEntry<String, String> entry) {
                final bool active = entry.key == recipient;
                return SyriusPillButton(
                  label: entry.value,
                  compact: true,
                  height: 27,
                  highlighted: active,
                  onPressed: () => setState(() {
                    _recipientController.text = entry.key;
                    _lookalikeDismissed = false;
                  }),
                );
              }),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 7,
              child: TextField(
                key: const Key('send_amount_field'),
                controller: _amountController,
                onChanged: (_) => setState(() {}),
                inputFormatters: FormatUtils.getAmountTextInputFormatters(
                  _amountController.text,
                ),
                style: tokens.monoStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: tokens.surfaceSubtle,
                  hintText: '0.0',
                  errorText: amountError,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: tokens.znnGreen,
                        minimumSize: const Size(40, 32),
                      ),
                      onPressed: available > BigInt.zero
                          ? () => setState(() {
                              _amountController.text = available.addDecimals(
                                _selectedToken.decimals,
                              );
                            })
                          : null,
                      child: Text(
                        context.l10n.max,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tokens.znnGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _buildTokenSelector(
                tokens,
                availableTokens,
                selected: _selectedToken,
                onSelected: (Token t) => setState(() => _selectedToken = t),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Text(
              '${context.l10n.available} '
              '${uiPrefs.hideBalances ? '••••' : _formatRaw(
                    available,
                    _selectedToken.decimals,
                  )} '
              '${_selectedToken.symbol}',
              style: tokens.monoStyle(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
        if (knownLabel != null && lookalike == null) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(Icons.info_outline, size: 14, color: tokens.textMuted),
              const SizedBox(width: 6),
              Text(
                knownLabel,
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        KeyedSubtree(
          key: const Key('send_submit_button'),
          child: SyriusGradientButton(
            expanded: true,
            height: 44,
            isLoading: _isSending,
            icon: isNodeBehind ? null : Icons.arrow_upward_rounded,
            label: isNodeBehind
                ? context.l10n.waitingForNode
                : amountText.isNotEmpty
                ? '${context.l10n.send} $amountText ${_selectedToken.symbol}'
                : context.l10n.send,
            onPressed: valid && !_isSending && !_sendDialogOpen
                ? () => unawaited(
                    _confirmAndSend(
                      context,
                      fromAddress: effectiveSender,
                      toAddress: recipient,
                      amountText: amountText,
                      token: _selectedToken,
                      knownLabel: knownLabel,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLookalikeWarning(
    BuildContext context,
    SyriusThemeTokens tokens,
    _LookalikeMatch match,
    String typed,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.warningSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: tokens.warning,
              ),
              const SizedBox(width: 7),
              Text(
                context.l10n.looksLikeContactButIsNot(match.label),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Same first and last characters, different middle.',
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
          const SizedBox(height: 10),
          SyriusKeyValueRow(
            label: match.label,
            labelWidth: 64,
            value: Text(
              match.address,
              style: tokens.monoStyle(
                fontSize: 11.5,
                color: tokens.textPrimary,
              ),
            ),
          ),
          SyriusKeyValueRow(
            label: 'TYPED',
            labelWidth: 64,
            value: Text(
              typed,
              style: tokens.monoStyle(fontSize: 11.5, color: tokens.warning),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              SyriusPillButton(
                label: 'Use ${match.label}',
                compact: true,
                onPressed: () => setState(() {
                  _recipientController.text = match.address;
                  _lookalikeDismissed = false;
                }),
              ),
              const SizedBox(width: 10),
              SyriusGhostButton(
                label: context.l10n.sendToTypedAddressAnyway,
                onPressed: () => setState(() => _lookalikeDismissed = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSend(
    BuildContext context, {
    required String fromAddress,
    required String toAddress,
    required String amountText,
    required Token token,
    String? knownLabel,
  }) async {
    if (_isSending || _sendDialogOpen) {
      return;
    }
    setState(() => _sendDialogOpen = true);
    final SyriusThemeTokens tokens = context.syriusTheme;
    final bool isLedger = kWalletFile?.isHardwareWallet ?? false;

    bool? confirmed;
    try {
      confirmed = await showSyriusBlurredDialog<bool>(
        context: context,
        maxWidth: 440,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          bool handled = false;
          return SyriusModalShell(
            title: '${context.l10n.send} $amountText ${token.symbol}?',
            showCloseButton: false,
            actions: <Widget>[
              SyriusPillButton(
                label: context.l10n.cancel,
                onPressed: () {
                  if (handled) {
                    return;
                  }
                  handled = true;
                  Navigator.of(dialogContext).pop(false);
                },
              ),
              SyriusGradientButton(
                label: context.l10n.send,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                onPressed: () {
                  if (handled) {
                    return;
                  }
                  handled = true;
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SyriusKeyValueRow(
                  label: context.l10n.to,
                  value: Wrap(
                    spacing: 8,
                    children: <Widget>[
                      if (knownLabel != null)
                        Text(
                          knownLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                      Text(
                        _shorten(toAddress),
                        style: tokens.monoStyle(
                          fontSize: 12.5,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SyriusKeyValueRow(
                  label: context.l10n.from,
                  value: Text(
                    ZenonAddressUtils.getLabel(fromAddress),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                SyriusKeyValueRow(
                  label: context.l10n.plasma,
                  value: Text(
                    'From fused QSR or PoW',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                if (isLedger) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.usb_rounded,
                          size: 16,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Confirm on the Ledger after Send.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _sendDialogOpen = false);
      }
    }

    if (!mounted || !(confirmed ?? false) || _isSending) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    setState(() {
      _isSending = true;
      _pendingSendSummary = _PendingSendSummary(
        amount: amountText,
        recipient: toAddress,
        sender: fromAddress,
        symbol: token.symbol,
      );
    });
    context.read<SendTransactionBloc>().add(
      SendTransactionInitiate(
        amount: amountText.extractDecimals(token.decimals),
        fromAddress: fromAddress,
        toAddress: toAddress,
        token: token,
      ),
    );
  }

  Widget _buildReceiveBody(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required String effectiveSender,
    required List<Token> availableTokens,
  }) {
    final String label = effectiveSender.isNotEmpty
        ? ZenonAddressUtils.getLabel(effectiveSender)
        : context.l10n.addressNumber(1);
    final BigInt reqAmount = _parseReceiveAmount();
    final String qrPayload =
        '${_receiveToken.symbol.toLowerCase()}:$effectiveSender'
        '?zts=${_receiveToken.tokenStandard}&amount=$reqAmount';

    if (!_showQr) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 6),
          Center(
            child: Text(label.toUpperCase(), style: tokens.microLabelStyle()),
          ),
          const SizedBox(height: 10),
          Center(
            child: SelectableText(
              effectiveSender,
              textAlign: TextAlign.center,
              style: tokens.monoStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SyriusGradientButton(
                label: context.l10n.copyAddress,
                icon: Icons.copy_rounded,
                height: 38,
                onPressed: effectiveSender.isEmpty
                    ? null
                    : () => unawaited(
                        Clipboard.setData(ClipboardData(text: effectiveSender)),
                      ),
              ),
              const SizedBox(width: 10),
              SyriusPillButton(
                label: context.l10n.showQr,
                icon: Icons.qr_code_2_rounded,
                height: 38,
                onPressed: () => setState(() => _showQr = true),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SyriusDivider(),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() {
              _showQr = true;
              _showAmountRequest = true;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: <Widget>[
                  Text(
                    context.l10n.requestSpecificAmount,
                    style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: tokens.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Screen 10: Expanded QR + Request specific amount
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 196,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ReceiveQrImage(
                  data: qrPayload,
                  tokenStandard: _receiveToken.tokenStandard,
                  size: 146,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SyriusGhostButton(
                    label: context.l10n.copyAddress,
                    icon: Icons.copy_rounded,
                    fontSize: 11.5,
                    onPressed: () => unawaited(
                      Clipboard.setData(ClipboardData(text: qrPayload)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SelectableText(
                effectiveSender,
                style: tokens.monoStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  SyriusGradientButton(
                    label: context.l10n.copyAddress,
                    icon: Icons.copy_rounded,
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    fontSize: 12.5,
                    onPressed: () => unawaited(
                      Clipboard.setData(ClipboardData(text: effectiveSender)),
                    ),
                  ),
                  SyriusPillButton(
                    label: context.l10n.hideQr,
                    icon: Icons.qr_code_2_rounded,
                    height: 34,
                    compact: true,
                    onPressed: () => setState(() => _showQr = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SyriusDivider(),
              const SizedBox(height: 10),
              InkWell(
                onTap: () =>
                    setState(() => _showAmountRequest = !_showAmountRequest),
                child: Row(
                  children: <Widget>[
                    Text(
                      context.l10n.requestSpecificAmount,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showAmountRequest
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: tokens.textMuted,
                    ),
                  ],
                ),
              ),
              if (_showAmountRequest) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _receiveAmountController,
                        onChanged: (_) => setState(() {}),
                        inputFormatters:
                            FormatUtils.getAmountTextInputFormatters(
                              _receiveAmountController.text,
                            ),
                        style: tokens.monoStyle(
                          fontSize: 15,
                          color: tokens.textPrimary,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: tokens.surfaceSubtle,
                          hintText: '100',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: _buildTokenSelector(
                        tokens,
                        availableTokens,
                        selected: _receiveToken,
                        onSelected: (Token t) =>
                            setState(() => _receiveToken = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The QR carries the amount. '
                  'Syrius and the extension read it.',
                  style: TextStyle(fontSize: 11.5, color: tokens.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZapBody(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required String effectiveSender,
    required AccountInfo? accountInfo,
  }) {
    final String target = _zapAddressController.text.trim();
    final String znnTxt = _zapZnnController.text.trim();
    final String qsrTxt = _zapQsrController.text.trim();
    final String msg = _zapMessageController.text;
    final double znnVal = double.tryParse(znnTxt) ?? 0;
    final double qsrVal = double.tryParse(qsrTxt) ?? 0;
    final bool validTarget =
        target.isNotEmpty && InputValidators.checkAddress(target) == null;
    final bool canZap =
        validTarget && (znnVal > 0 || qsrVal > 0) && !_isZapping;

    final List<String> parts = <String>[
      if (znnVal > 0) '$znnTxt ZNN',
      if (qsrVal > 0) '$qsrTxt QSR',
    ];
    final String ctaLabel = parts.isEmpty
        ? context.l10n.zap
        : '${context.l10n.zap} ${parts.join(' + ')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              context.l10n.randomAlien.toUpperCase(),
              style: tokens.microLabelStyle(),
            ),
            const Spacer(),
            Text(
              'Active addresses from recent activity',
              style: TextStyle(fontSize: 11.5, color: tokens.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _zapAddressController,
                onChanged: (_) => setState(() {}),
                style: tokens.monoStyle(
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: tokens.surfaceSubtle,
                  hintText: context.l10n.recipientAddress,
                  suffixIcon: IconButton(
                    iconSize: 15,
                    color: tokens.textMuted,
                    onPressed: target.isEmpty
                        ? null
                        : () => unawaited(
                            Clipboard.setData(ClipboardData(text: target)),
                          ),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SyriusPillButton(
              label: context.l10n.pickAnother,
              icon: Icons.casino_outlined,
              height: 44,
              onPressed: () => _pickRandomAlien(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _zapZnnController,
                onChanged: (_) => setState(() {}),
                inputFormatters: FormatUtils.getAmountTextInputFormatters(
                  _zapZnnController.text,
                ),
                style: tokens.monoStyle(
                  fontSize: 15,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: tokens.surfaceSubtle,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(10),
                    child: SyriusTokenAvatar(symbol: 'ZNN', size: 22),
                  ),
                  suffixText: 'ZNN',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _zapQsrController,
                onChanged: (_) => setState(() {}),
                inputFormatters: FormatUtils.getAmountTextInputFormatters(
                  _zapQsrController.text,
                ),
                style: tokens.monoStyle(
                  fontSize: 15,
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: tokens.surfaceSubtle,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(10),
                    child: SyriusTokenAvatar(symbol: 'QSR', size: 22),
                  ),
                  suffixText: 'QSR',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: <Widget>[
            TextField(
              controller: _zapMessageController,
              maxLength: 140,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13.5, color: tokens.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: tokens.surfaceSubtle,
                counterText: '',
                hintText: 'You got zapped. Have a great day, alien.',
              ),
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: Text(
                '${msg.length}/140',
                style: tokens.monoStyle(fontSize: 11, color: tokens.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          znnVal > 0 && qsrVal > 0
              ? 'Two blocks, one per coin'
              : 'One account block with optional UTF-8 message',
          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
        ),
        const SizedBox(height: 16),
        SyriusGradientButton(
          expanded: true,
          height: 44,
          icon: Icons.bolt_rounded,
          label: ctaLabel,
          isLoading: _isZapping,
          onPressed: canZap
              ? () => _executeZap(
                  context,
                  fromAddress: effectiveSender,
                  toAddress: target,
                  znnText: znnTxt,
                  qsrText: qsrTxt,
                  message: msg.trim(),
                )
              : null,
        ),
      ],
    );
  }

  void _pickRandomAlien(BuildContext context) {
    final List<AccountBlock> history =
        context.read<LatestTransactionsBloc>().state.data ??
        const <AccountBlock>[];
    final Set<String> candidates = <String>{};
    for (final AccountBlock block in history) {
      final String from = block.address.toString();
      final String to = block.toAddress.toString();
      if (from != kSelectedAddress &&
          InputValidators.checkAddress(from) == null) {
        candidates.add(from);
      }
      if (to != kSelectedAddress &&
          InputValidators.checkAddress(to) == null &&
          !embeddedContractAddresses.contains(block.toAddress)) {
        candidates.add(to);
      }
    }
    if (candidates.isEmpty) {
      for (final String? addr in kDefaultAddressList) {
        if (addr != null && addr != kSelectedAddress) {
          candidates.add(addr);
        }
      }
    }
    if (candidates.isNotEmpty) {
      final List<String> list = candidates.toList();
      final String chosen = list[Random().nextInt(list.length)];
      setState(() => _zapAddressController.text = chosen);
    }
  }

  Future<void> _executeZap(
    BuildContext context, {
    required String fromAddress,
    required String toAddress,
    required String znnText,
    required String qsrText,
    required String message,
  }) async {
    if (_isZapping || _isSending) {
      return;
    }
    setState(() => _isZapping = true);
    final SendTransactionBloc zapBloc = SendTransactionBloc();
    final String zapReason = context.l10n.zap;
    try {
      final List<int> dataBytes = message.isNotEmpty
          ? utf8.encode(message)
          : const <int>[];
      final double znnVal = double.tryParse(znnText) ?? 0;
      final double qsrVal = double.tryParse(qsrText) ?? 0;

      Future<bool> submitBlock(AccountBlockTemplate block) async {
        final Future<SendTransactionState> resultFuture = zapBloc.stream
            .firstWhere(
              (SendTransactionState s) =>
                  s.status == SendTransactionStatus.success ||
                  s.status == SendTransactionStatus.failure,
            );
        zapBloc.add(
          SendTransactionInitiateFromBlock(
            block: block,
            fromAddress: fromAddress,
            reasonForGeneratingPlasma: zapReason,
          ),
        );
        final SendTransactionState result = await resultFuture;
        if (result.status == SendTransactionStatus.failure) {
          if (result.error != null) {
            await NotificationUtils.sendNotificationError(
              result.error!,
              zapReason,
            );
          }
          return false;
        }
        return true;
      }

      bool allSucceeded = true;
      if (znnVal > 0) {
        final AccountBlockTemplate znnBlock = AccountBlockTemplate.send(
          Address.parse(toAddress),
          kZnnCoin.tokenStandard,
          znnText.extractDecimals(kZnnCoin.decimals),
          dataBytes,
        );
        allSucceeded = await submitBlock(znnBlock);
      }
      if (allSucceeded && qsrVal > 0) {
        final AccountBlockTemplate qsrBlock = AccountBlockTemplate.send(
          Address.parse(toAddress),
          kQsrCoin.tokenStandard,
          qsrText.extractDecimals(kQsrCoin.decimals),
          znnVal > 0 ? const <int>[] : dataBytes,
        );
        allSucceeded = await submitBlock(qsrBlock);
      }
      if (allSucceeded && mounted) {
        _zapMessageController.clear();
      }
    } finally {
      await zapBloc.close();
      if (mounted) {
        setState(() => _isZapping = false);
      }
    }
  }

  Widget _buildToReceiveCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final bool autoReceiveEnabled = _readAutoReceivePref();
    return BlocBuilder<
      PendingTransactionsBloc,
      InfiniteListState<AccountBlock>
    >(
      builder: (BuildContext context, InfiniteListState<AccountBlock> state) {
        final List<AccountBlock> pending = state.data ?? const <AccountBlock>[];
        return SyriusCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                child: Row(
                  children: <Widget>[
                    Text(
                      context.l10n.toReceive,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (pending.isNotEmpty)
                      Text(
                        '${pending.length}',
                        style: tokens.monoStyle(
                          fontSize: 12,
                          color: tokens.textMuted,
                        ),
                      ),
                    const Spacer(),
                    if (pending.isEmpty)
                      Text(
                        context.l10n.noneYet,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tokens.textMuted,
                        ),
                      )
                    else
                      SyriusPillButton(
                        label: autoReceiveEnabled
                            ? context.l10n.autoReceiveOn
                            : context.l10n.autoReceiveOff,
                        compact: true,
                        onPressed: () {
                          final bool next = !autoReceiveEnabled;
                          if (sharedPrefsService != null) {
                            unawaited(
                              sharedPrefsService!.put(kAutoReceiveKey, next),
                            );
                          }
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
              if (pending.isNotEmpty) ...<Widget>[
                const SyriusDivider(),
                for (int i = 0; i < pending.length; i++) ...<Widget>[
                  if (i > 0) const SyriusDivider(),
                  _buildPendingReceiveRow(tokens, uiPrefs, pending[i]),
                ],
                if (!state.hasReachedMax) ...<Widget>[
                  const SyriusDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SyriusGhostButton(
                        label: context.l10n.seeMore,
                        onPressed: () {
                          final String? addr = kSelectedAddress;
                          if (addr != null) {
                            context.read<PendingTransactionsBloc>().add(
                              InfiniteListMoreRequested(
                                address: Address.parse(addr),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingReceiveRow(
    SyriusThemeTokens tokens,
    AppUiPreferencesNotifier uiPrefs,
    AccountBlock block,
  ) {
    final String symbol = block.token?.symbol ?? kZnnCoin.symbol;
    final int decimals = block.token?.decimals ?? kZnnCoin.decimals;
    final String amt = uiPrefs.hideBalances
        ? '•••• $symbol'
        : '${_formatRaw(block.amount, decimals)} $symbol';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              _shorten(block.address.toString()),
              style: tokens.monoStyle(
                fontSize: 12.5,
                color: tokens.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amt,
              textAlign: TextAlign.right,
              style: tokens.monoStyle(
                fontWeight: FontWeight.w500,
                color: tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: ReceiveCell(hash: block.hash),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenSelector(
    SyriusThemeTokens tokens,
    List<Token> options, {
    required Token selected,
    required ValueChanged<Token> onSelected,
  }) {
    return PopupMenuButton<Token>(
      color: tokens.surface,
      onSelected: onSelected,
      itemBuilder: (_) => options.map((Token t) {
        return PopupMenuItem<Token>(
          value: t,
          child: Row(
            children: <Widget>[
              SyriusTokenAvatar(
                symbol: t.symbol,
                color: ColorUtils.getTokenColor(t.tokenStandard),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t.symbol,
                style: TextStyle(fontSize: 13, color: tokens.textPrimary),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: <Widget>[
            SyriusTokenAvatar(
              symbol: selected.symbol,
              color: ColorUtils.getTokenColor(selected.tokenStandard),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected.symbol,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: tokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _onSendStateChanged(BuildContext context, SendTransactionState state) {
    final _PendingSendSummary? summary = _pendingSendSummary;
    if (summary == null) {
      return;
    }
    if (state.status == SendTransactionStatus.loading) {
      if (!_isSending) {
        setState(() => _isSending = true);
      }
    } else if (state.status == SendTransactionStatus.success) {
      _pendingSendSummary = null;
      final String recipientLabel = ZenonAddressUtils.getLabel(
        summary.recipient,
      );
      final String senderLabel = ZenonAddressUtils.getLabel(summary.sender);
      if (state.data != null) {
        unawaited(
          sl.get<NotificationsBloc>().addNotification(
            WalletNotification(
              title: context.l10n.sentDetails(
                summary.amount,
                recipientLabel,
                senderLabel,
                summary.symbol,
              ),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: context.l10n.hashValue(state.data!.hash.toString()),
              type: NotificationType.paymentSent,
            ),
          ),
        );
      }
      setState(() {
        _isSending = false;
        _amountController.clear();
        _recipientController.clear();
        _lookalikeDismissed = false;
      });
    } else if (state.status == SendTransactionStatus.failure) {
      _pendingSendSummary = null;
      setState(() => _isSending = false);
      if (state.error != null) {
        unawaited(
          NotificationUtils.sendNotificationError(
            state.error!,
            context.l10n.couldNotSend(
              summary.amount,
              ZenonAddressUtils.getLabel(summary.recipient),
              summary.symbol,
            ),
          ),
        );
      }
    }
  }

  _LookalikeMatch? _detectLookalikeAddress(
    String typed,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    if (typed.length < 16 || InputValidators.checkAddress(typed) != null) {
      return null;
    }
    final Map<String, String> known = <String, String>{
      ...kAddressLabelMap,
      ...uiPrefs.contacts,
    };
    final String prefix = typed.substring(0, 6);
    final String suffix = typed.substring(typed.length - 4);
    for (final MapEntry<String, String> entry in known.entries) {
      final String addr = entry.key;
      if (addr == typed || addr.length < 16) {
        continue;
      }
      if (addr.startsWith(prefix) && addr.endsWith(suffix)) {
        return _LookalikeMatch(address: addr, label: entry.value);
      }
    }
    return null;
  }

  List<MapEntry<String, String>> _buildRecentRecipients(
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final Map<String, String> out = <String, String>{};
    for (final MapEntry<String, String> c in uiPrefs.contacts.entries) {
      out[c.key] = c.value;
    }
    for (final String? addr in kDefaultAddressList) {
      if (addr != null && addr != _senderAddress && !out.containsKey(addr)) {
        out[addr] = ZenonAddressUtils.getLabel(addr);
      }
    }
    return out.entries.take(4).toList();
  }

  BigInt _parseReceiveAmount() {
    try {
      if (_receiveAmountController.text.trim().isEmpty) {
        return BigInt.zero;
      }
      return _receiveAmountController.text.trim().extractDecimals(
        _receiveToken.decimals,
      );
    } on Object catch (_) {
      return BigInt.zero;
    }
  }

  bool _readAutoReceivePref() {
    try {
      return sharedPrefsService?.get(
                kAutoReceiveKey,
                defaultValue: kAutoReceiveDefaultValue,
              )
              as bool? ??
          kAutoReceiveDefaultValue;
    } on Object catch (_) {
      return kAutoReceiveDefaultValue;
    }
  }

  NodeSyncStatusCubit? _tryReadSyncCubit(BuildContext context) {
    try {
      return context.watch<NodeSyncStatusCubit>();
    } on Object catch (_) {
      return null;
    }
  }

  static String _formatRaw(BigInt raw, int decimals) {
    final String s = raw.addDecimals(decimals);
    final double? n = double.tryParse(s);
    return n != null ? _amountFormat.format(n) : s;
  }

  static String _shorten(String address) {
    if (address.length <= 14) {
      return address;
    }
    return '${address.substring(0, 6)}...'
        '${address.substring(address.length - 4)}';
  }
}

class _LookalikeMatch {
  const _LookalikeMatch({required this.address, required this.label});

  final String address;
  final String label;
}

class _PendingSendSummary {
  const _PendingSendSummary({
    required this.amount,
    required this.recipient,
    required this.sender,
    required this.symbol,
  });

  final String amount;
  final String recipient;
  final String sender;
  final String symbol;
}
