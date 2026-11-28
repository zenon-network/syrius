import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A modal containing the form used to start a native P2P swap (Screen 27).
class StartP2pSwapModal extends StatelessWidget {
  /// Creates a native-swap modal.
  const StartP2pSwapModal({super.key});

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final ValueNotifier<Token> _tokenNotifier = ValueNotifier<Token>(kZnnCoin);
  final ValueNotifier<String> _sender = ValueNotifier<String>(
    kSelectedAddress!,
  );
  final TextEditingController _counterpartyAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Token get _token => _tokenNotifier.value;
  String get _amount => _amountController.text;
  String get _counterpartyAddress => _counterpartyAddressController.text;
  String? get _counterpartyAddressError =>
      _validateCounterpartyAddress(_counterpartyAddress);

  @override
  void initState() {
    super.initState();
    context.read<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.whereType<String>().toList(),
      ),
    );
  }

  @override
  void dispose() {
    _tokenNotifier.dispose();
    _sender.dispose();
    _counterpartyAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SyriusModalShell(
        title: context.l10n.startSwap,
        headerTrailing: TextButton(
          onPressed: () {
            unawaited(NavigationUtils.openUrl(kP2pSwapTutorialLink));
          },
          child: Text(
            context.l10n.howItWorks,
            style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
          ),
        ),
        child: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
          builder: (_, MultipleBalanceState balanceState) =>
              switch (balanceState.status) {
                MultipleBalanceStatus.failure => SyriusErrorWidget(
                  balanceState.error!,
                ),
                MultipleBalanceStatus.initial ||
                MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
                MultipleBalanceStatus.success => _buildContent(
                  context,
                  tokens,
                  balances: balanceState.data!,
                ),
              },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required Map<String, AccountInfo> balances,
  }) {
    return BlocConsumer<StartP2pSwapBloc, StartP2pSwapState>(
      listener: _onStartP2pSwapStateChanged,
      builder: (BuildContext context, StartP2pSwapState swapState) {
        final bool isSwapLoading = swapState is StartP2pSwapLoading;

        return ListenableBuilder(
          listenable: Listenable.merge(<Listenable?>[
            _amountController,
            _counterpartyAddressController,
            _sender,
            _tokenNotifier,
          ]),
          builder: (_, _) {
            final AccountInfo accountInfo = balances[_sender.value]!;
            final List<Token> availableTokens = getTokensWithBalance(
              accountInfo: accountInfo,
            );
            final BigInt balance = accountInfo.getBalance(_token.tokenStandard);
            final String? amountError = InputValidators.correctValue(
              _amount,
              balance,
              _token.decimals,
              BigInt.zero,
              l10n: context.l10n,
            );
            final bool isInputValid =
                _counterpartyAddress.isNotEmpty &&
                _counterpartyAddressError == null &&
                _amount.isNotEmpty &&
                amountError == null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            context.l10n.youSend.toUpperCase(),
                            style: tokens.microLabelStyle(),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            enabled: !isSwapLoading,
                            onSelected: (String value) {
                              _sender.value = value;
                            },
                            itemBuilder: (_) => kDefaultAddressList
                                .whereType<String>()
                                .map(
                                  (String addr) => PopupMenuItem<String>(
                                    value: addr,
                                    child: Text(kAddressLabelMap[addr] ?? addr),
                                  ),
                                )
                                .toList(),
                            child: Text(
                              '${kAddressLabelMap[_sender.value] ?? ''} · '
                              '${balance.addDecimals(_token.decimals)} '
                              '${_token.symbol}',
                              style: tokens.monoStyle(
                                fontSize: 11.5,
                                color: tokens.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              key: const Key('start_p2p_swap_amount_field'),
                              controller: _amountController,
                              enabled: !isSwapLoading,
                              inputFormatters:
                                  FormatUtils.getAmountTextInputFormatters(
                                    _amountController.text,
                                  ),
                              style: tokens.monoStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: tokens.textPrimary,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: '0',
                                errorText: _amount.isNotEmpty
                                    ? amountError
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<Token>(
                            enabled: !isSwapLoading,
                            onSelected: (Token next) {
                              _tokenNotifier.value = next;
                            },
                            itemBuilder: (_) => availableTokens
                                .map(
                                  (Token t) => PopupMenuItem<Token>(
                                    value: t,
                                    child: Row(
                                      children: <Widget>[
                                        SyriusTokenAvatar(
                                          symbol: t.symbol,
                                          color: ColorUtils.getTokenColor(
                                            t.tokenStandard,
                                          ),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(t.symbol),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: tokens.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  SyriusTokenAvatar(
                                    symbol: _token.symbol,
                                    color: ColorUtils.getTokenColor(
                                      _token.tokenStandard,
                                    ),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _token.symbol,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 14,
                                    color: tokens.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.counterparty.toUpperCase(),
                  style: tokens.microLabelStyle(),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('start_p2p_swap_counterparty_address_field'),
                  controller: _counterpartyAddressController,
                  enabled: !isSwapLoading,
                  style: tokens.monoStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: context.l10n.p2pSwapAddressHint,
                    errorText: _counterpartyAddress.isNotEmpty
                        ? _counterpartyAddressError
                        : null,
                    suffixIcon: PasteContentButton(
                      controller: _counterpartyAddressController,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Text(
                      context.l10n.p2pSwapReclaimFunds(
                        context.l10n.p2pSwapHours(kInitialHtlcDuration.inHours),
                      ),
                      style: TextStyle(fontSize: 11.5, color: tokens.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: tokens.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.experimentalSwapWarning,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    SyriusPillButton(
                      label: context.l10n.cancel,
                      onPressed: isSwapLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    SyriusGradientButton(
                      key: const Key('start_p2p_swap_submit_button'),
                      label: context.l10n.startSwap,
                      height: 36,
                      isLoading: isSwapLoading,
                      onPressed: isInputValid && !isSwapLoading
                          ? () => _onStartButtonPressed(context)
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onStartButtonPressed(BuildContext context) {
    context.read<StartP2pSwapBloc>().add(
      StartP2pSwapRequested(
        selfAddress: Address.parse(_sender.value),
        counterpartyAddress: Address.parse(_counterpartyAddressController.text),
        fromToken: _token,
        fromAmount: _amountController.text.extractDecimals(_token.decimals),
      ),
    );
  }

  void _onStartP2pSwapStateChanged(
    BuildContext context,
    StartP2pSwapState state,
  ) {
    if (state is StartP2pSwapDone) {
      Navigator.pop(context);
    }
  }

  String? _validateCounterpartyAddress(String? address) {
    final String? result = InputValidators.checkAddress(
      address,
      l10n: context.l10n,
    );
    if (result != null) {
      return result;
    }
    return kDefaultAddressList.contains(address)
        ? context.l10n.p2pSwapOwnAddressError
        : null;
  }
}
