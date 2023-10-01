import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/start_htlc_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/htlc_swap.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/bullet_point_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dropdown/addresses_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/amount_input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/labeled_input_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/modals/base_modal.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StartNativeSwapModal extends StatefulWidget {
  final Function(String) onSwapStarted;

  const StartNativeSwapModal({
    required this.onSwapStarted,
    Key? key,
  }) : super(key: key);

  @override
  State<StartNativeSwapModal> createState() => _StartNativeSwapModalState();
}

class _StartNativeSwapModalState extends State<StartNativeSwapModal> {
  Token _selectedToken = kZnnCoin;
  String? _selectedSelfAddress = kSelectedAddress;
  bool _isAmountValid = false;

  final TextEditingController _counterpartyAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
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
      title: 'Start swap',
      child: _getContent(),
    );
  }

  Widget _getContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20.0),
        Row(
          children: [
            Expanded(
              child: LabeledInputContainer(
                labelText: 'Your address',
                inputWidget: AddressesDropdown(
                  _selectedSelfAddress,
                  (address) => setState(() {
                    _selectedSelfAddress = address;
                    sl.get<BalanceBloc>().getBalanceForAllAddresses();
                  }),
                ),
              ),
            ),
            const SizedBox(
              width: 20.0,
            ),
            Expanded(
              child: LabeledInputContainer(
                labelText: 'Counterparty address',
                helpText: 'The address of the trading partner for the swap.',
                inputWidget: Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: InputField(
                    onChanged: (value) {
                      setState(() {});
                    },
                    enabled: !_isLoading,
                    validator: (value) => _validateCounterpartyAddress(value),
                    controller: _counterpartyAddressController,
                    suffixIcon: RawMaterialButton(
                      shape: const CircleBorder(),
                      onPressed: () {
                        ClipboardUtils.pasteToClipboard(context,
                            (String value) {
                          _counterpartyAddressController.text = value;
                          setState(() {});
                        });
                      },
                      child: const Icon(
                        Icons.content_paste,
                        color: AppColors.darkHintTextColor,
                        size: 15.0,
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      maxWidth: 45.0,
                      maxHeight: 20.0,
                    ),
                    hintText: 'Enter NoM address',
                    contentLeftPadding: 10.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        kVerticalSpacing,
        LabeledInputContainer(
          labelText: 'You are sending',
          inputWidget: Flexible(
            child: StreamBuilder<Map<String, AccountInfo>?>(
              stream: sl.get<BalanceBloc>().stream,
              builder: (_, snapshot) {
                if (snapshot.hasError) {
                  return SyriusErrorWidget(snapshot.error!);
                }
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return AmountInputField(
                      controller: _amountController,
                      enabled: !_isLoading,
                      accountInfo: (snapshot.data![_selectedSelfAddress]!),
                      valuePadding: 10.0,
                      textColor: Theme.of(context).colorScheme.inverseSurface,
                      initialToken: _selectedToken,
                      hintText: '0.0',
                      onChanged: (token, isValid) {
                        if (!_isLoading) {
                          setState(() {
                            _selectedToken = token;
                            _isAmountValid = isValid;
                          });
                        }
                      },
                    );
                  } else {
                    return const SyriusLoadingWidget();
                  }
                } else {
                  return const SyriusLoadingWidget();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20.0),
        BulletPointCard(
          bulletPoints: [
            RichText(
              text: BulletPointCard.textSpan(
                  'After starting the swap, wait for the counterparty to join the swap with the agreed upon amount.'),
            ),
            RichText(
              text: BulletPointCard.textSpan(
                '''You can reclaim your funds in ''',
                children: [
                  TextSpan(
                      text: '${kInitialHtlcDuration.inHours} hours',
                      style:
                          const TextStyle(fontSize: 14.0, color: Colors.white)),
                  BulletPointCard.textSpan(
                      ' if the counterparty fails to join the swap.'),
                ],
              ),
            ),
            RichText(
              text: BulletPointCard.textSpan(
                  'The swap must be completed on this machine.'),
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        _getStartSwapViewModel(),
      ],
    );
  }

  _getStartSwapViewModel() {
    return ViewModelBuilder<StartHtlcSwapBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) async {
            if (event is HtlcSwap) {
              widget.onSwapStarted.call(event.id);
            }
          },
          onError: (error) {
            setState(() {
              _isLoading = false;
            });
            ToastUtils.showToast(context, error.toString());
          },
        );
      },
      builder: (_, model, __) => _getStartSwapButton(model),
      viewModelBuilder: () => StartHtlcSwapBloc(),
    );
  }

  Widget _getStartSwapButton(StartHtlcSwapBloc model) {
    return InstructionButton(
      text: 'Start swap',
      instructionText: 'Fill in the swap details',
      loadingText: 'Sending transaction',
      isEnabled: _isInputValid(),
      isLoading: _isLoading,
      onPressed: () => _onStartButtonPressed(model),
    );
  }

  void _onStartButtonPressed(StartHtlcSwapBloc model) async {
    setState(() {
      _isLoading = true;
    });
    model.startHtlcSwap(
        selfAddress: Address.parse(_selectedSelfAddress!),
        counterpartyAddress: Address.parse(_counterpartyAddressController.text),
        fromToken: _selectedToken,
        fromAmount:
            _amountController.text.extractDecimals(_selectedToken.decimals),
        hashType: htlcHashTypeSha3,
        swapType: P2pSwapType.native,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        initialHtlcDuration: kInitialHtlcDuration.inSeconds);
  }

  bool _isInputValid() =>
      _validateCounterpartyAddress(_counterpartyAddressController.text) ==
          null &&
      _isAmountValid;

  String? _validateCounterpartyAddress(String? address) {
    String? result = InputValidators.checkAddress(address);
    if (result != null) {
      return result;
    } else {
      return kDefaultAddressList.contains(address)
          ? 'Cannot swap with your own address'
          : null;
    }
  }
}
