import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A modal containing the form used to start a native P2P swap.
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
  final ValueNotifier<Token> _tokenNotifier = .new(kZnnCoin);

  Token get _token => _tokenNotifier.value;

  final ValueNotifier<String> _sender = .new(kSelectedAddress!);

  final TextEditingController _counterpartyAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String get _amount => _amountController.text;

  String get _counterpartyAddress => _counterpartyAddressController.text;

  String? get _counterpartyAddressError =>
      _validateCounterpartyAddress(_counterpartyAddress);

  @override
  void initState() {
    super.initState();
    context.read<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList
            .map((String? address) => address!)
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    _counterpartyAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: context.l10n.p2pSwapStart,
      child: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
        builder: (_, MultipleBalanceState balanceState) =>
            switch (balanceState.status) {
              MultipleBalanceStatus.failure => SyriusErrorWidget(
                balanceState.error!,
              ),
              MultipleBalanceStatus.initial => const SyriusLoadingWidget(),
              MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
              MultipleBalanceStatus.success => _buildContent(
                balances: balanceState.data!,
              ),
            },
      ),
    );
  }

  Widget _buildContent({
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

            final String? amountError = InputValidators.correctValue(
              _amount,
              accountInfo.getBalance(
                _token.tokenStandard,
              ),
              _token.decimals,
              BigInt.zero,
            );

            final bool isInputValid =
                _counterpartyAddress.isNotEmpty &&
                _counterpartyAddressError == null &&
                _amount.isNotEmpty &&
                amountError == null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: kVerticalGap16.height!,
              children: <Widget>[
                kVerticalGap16,
                Row(
                  children: <Widget>[
                    Expanded(
                      child: NewAddressesDropdown(
                        addresses: kDefaultAddressList
                            .map((String? e) => e!)
                            .toList(),
                        enabled: !isSwapLoading,
                        label: Text(context.l10n.yourAddress),
                        selectedAddress: _sender,
                      ),
                    ),
                    kHorizontalGap16,
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          errorText: _counterpartyAddress.isNotEmpty
                              ? _counterpartyAddressError
                              : null,
                          hintText: context.l10n.p2pSwapAddressHint,
                          labelText: context.l10n.counterpartyAddress,
                          suffixIcon: PasteContentButton(
                            controller: _counterpartyAddressController,
                          ),
                        ),
                        enabled: !isSwapLoading,
                        controller: _counterpartyAddressController,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AmountTextField(
                        accountInfo: accountInfo,
                        controller: _amountController,
                        enabled: !isSwapLoading,
                        errorText: _amount.isNotEmpty ? amountError : null,
                        labelText: context.l10n.youAreSending,
                        token: _token,
                        onSubmitted: (_) {},
                      ),
                    ),
                    kHorizontalGap16,
                    Expanded(
                      child: ZtsDropdown(
                        availableTokens: getTokensWithBalance(
                          accountInfo: accountInfo,
                        ),
                        enabled: !isSwapLoading,
                        label: Text(context.l10n.asset),
                        selectedToken: _tokenNotifier,
                      ),
                    ),
                  ],
                ),
                BulletPointCard(
                  bulletPoints: <String>[
                    context.l10n.p2pSwapWaitForCounterparty,
                    context.l10n.p2pSwapReclaimFunds(
                      context.l10n.p2pSwapHours(
                        kInitialHtlcDuration.inHours,
                      ),
                    ),
                    context.l10n.p2pSwapMachineOnly,
                  ],
                ),
                _buildStartSwapButton(
                  isInputValid: isInputValid,
                  isLoading: isSwapLoading,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStartSwapButton({
    required bool isLoading,
    required bool isInputValid,
  }) {
    return InstructionButton(
      text: context.l10n.p2pSwapStart,
      instructionText: context.l10n.p2pSwapFillDetails,
      loadingText: context.l10n.sendingTransaction,
      isEnabled: isInputValid,
      isLoading: isLoading,
      onPressed: () => _onStartButtonPressed(context),
    );
  }

  void _onStartButtonPressed(BuildContext context) {
    context.read<StartP2pSwapBloc>().add(
      StartP2pSwapRequested(
        selfAddress: Address.parse(_sender.value),
        counterpartyAddress: Address.parse(_counterpartyAddressController.text),
        fromToken: _token,
        fromAmount: _amountController.text.extractDecimals(
          _token.decimals,
        ),
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
    final String? result = InputValidators.checkAddress(address);
    if (result != null) {
      return result;
    } else {
      // TODO(maznnwell): loose check to see if two addresses are from the same
      //  seed, but also probably impossible to check properly
      return kDefaultAddressList.contains(address)
          ? context.l10n.p2pSwapOwnAddressError
          : null;
    }
  }
}
