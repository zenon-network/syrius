import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/initial_htlc_for_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/join_htlc_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/htlc_swap.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/htlc_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/bullet_point_card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/exchange_rate_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/important_text_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/input_fields.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/modals/base_modal.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class JoinNativeSwapModal extends StatefulWidget {

  const JoinNativeSwapModal({
    required this.onJoinedSwap,
    super.key,
  });
  final Function(String) onJoinedSwap;

  @override
  State<JoinNativeSwapModal> createState() => _JoinNativeSwapModalState();
}

class _JoinNativeSwapModalState extends State<JoinNativeSwapModal> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _depositIdController = TextEditingController();

  late String _selfAddress;

  HtlcInfo? _initialHltc;
  String? _initialHtlcError;
  int? _safeExpirationTime;
  StreamSubscription? _safeExpirationSubscription;

  Token _selectedToken = kZnnCoin;
  bool _isAmountValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
    _safeExpirationSubscription =
        Stream.periodic(const Duration(seconds: 5)).listen((_) {
      if (_initialHltc != null) {
        _safeExpirationTime =
            _calculateSafeExpirationTime(_initialHltc!.expirationTime);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _safeExpirationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Join swap',
      child: _initialHltc == null
          ? _getSearchView()
          : FutureBuilder<Token?>(
              future:
                  zenon!.embedded.token.getByZts(_initialHltc!.tokenStandard),
              builder: (_, AsyncSnapshot<Token?> snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: SyriusErrorWidget(snapshot.error!),
                  );
                } else if (snapshot.hasData) {
                  return _getContent(snapshot.data!);
                }
                return const Padding(
                  padding: EdgeInsets.all(50),
                  child: SyriusLoadingWidget(),
                );
              },
            ),
    );
  }

  Widget _getSearchView() {
    return Column(
      children: <Widget>[
        const SizedBox(
          height: 20,
        ),
        Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            onChanged: (String value) {
              setState(() {});
            },
            validator: InputValidators.checkHash,
            controller: _depositIdController,
            suffixIcon: RawMaterialButton(
              shape: const CircleBorder(),
              onPressed: () => ClipboardUtils.pasteToClipboard(
                context,
                (String value) {
                  _depositIdController.text = value;
                  setState(() {});
                },
              ),
              child: const Icon(
                Icons.content_paste,
                color: AppColors.darkHintTextColor,
                size: 15,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              maxWidth: 45,
              maxHeight: 20,
            ),
            hintText: 'Deposit ID provided by the counterparty',
            contentLeftPadding: 10,
          ),
        ),
        const SizedBox(
          height: 25,
        ),
        Visibility(
          visible: _initialHtlcError != null,
          child: Column(
            children: <Widget>[
              ImportantTextContainer(
                text: _initialHtlcError ?? '',
                showBorder: true,
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
        _getInitialHtlcViewModel(),
      ],
    );
  }

  ViewModelBuilder<InitialHtlcForSwapBloc> _getInitialHtlcViewModel() {
    return ViewModelBuilder<InitialHtlcForSwapBloc>.reactive(
      onViewModelReady: (InitialHtlcForSwapBloc model) {
        model.stream.listen(
          (HtlcInfo? event) async {
            if (event is HtlcInfo) {
              _initialHltc = event;
              _isLoading = false;
              _addressController.text = event.hashLocked.toString();
              _selfAddress = event.hashLocked.toString();
              _safeExpirationTime =
                  _calculateSafeExpirationTime(event.expirationTime);
              _initialHtlcError = null;
              setState(() {});
            }
          },
          onError: (error) {
            setState(() {
              _initialHtlcError = error.toString();
              _isLoading = false;
            });
          },
        );
      },
      builder: (_, InitialHtlcForSwapBloc model, __) => _getContinueButton(model),
      viewModelBuilder: InitialHtlcForSwapBloc.new,
    );
  }

  Widget _getContinueButton(InitialHtlcForSwapBloc model) {
    return InstructionButton(
      text: 'Continue',
      loadingText: 'Searching',
      instructionText: 'Input the deposit ID',
      isEnabled: _isHashValid(),
      isLoading: _isLoading,
      onPressed: () => _onContinueButtonPressed(model),
    );
  }

  Future<void> _onContinueButtonPressed(InitialHtlcForSwapBloc model) async {
    setState(() {
      _isLoading = true;
      _initialHtlcError = null;
    });
    model.getInitialHtlc(Hash.parse(_depositIdController.text));
  }

  Widget _getContent(Token tokenToReceive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: LabeledInputContainer(
                labelText: 'Your address',
                helpText: 'You will receive the swapped funds to this address.',
                inputWidget: DisabledAddressField(
                  _addressController,
                  contentLeftPadding: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Divider(color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 20),
        LabeledInputContainer(
          labelText: 'You are sending',
          inputWidget: Flexible(
            child: StreamBuilder<Map<String, AccountInfo>?>(
              stream: sl.get<BalanceBloc>().stream,
              builder: (_, AsyncSnapshot<Map<String, AccountInfo>?> snapshot) {
                if (snapshot.hasError) {
                  return SyriusErrorWidget(snapshot.error!);
                }
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return AmountInputField(
                      controller: _amountController,
                      accountInfo: snapshot.data![_selfAddress]!,
                      valuePadding: 10,
                      textColor: Theme.of(context).colorScheme.inverseSurface,
                      initialToken: _selectedToken,
                      hintText: '0.0',
                      onChanged: (Token token, bool isValid) {
                        setState(() {
                          _selectedToken = token;
                          _isAmountValid = isValid;
                        });
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
        kVerticalSpacing,
        const Icon(
          AntDesign.arrowdown,
          color: Colors.white,
          size: 20,
        ),
        kVerticalSpacing,
        HtlcCard.fromHtlcInfo(
          title: 'You are receiving',
          htlc: _initialHltc!,
          token: tokenToReceive,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Exchange Rate',
                style:
                    TextStyle(fontSize: 14, color: AppColors.subtitleColor),
              ),
              _getExchangeRateWidget(tokenToReceive),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Divider(color: Colors.white.withOpacity(0.1)),
        if (_safeExpirationTime != null) const SizedBox(height: 20),
        if (_safeExpirationTime != null)
          BulletPointCard(
            bulletPoints: <RichText>[
              RichText(
                text: BulletPointCard.textSpan(
                  'You have ',
                  children: <TextSpan>[
                    TextSpan(
                        text:
                            '${(((_initialHltc!.expirationTime - kMinSafeTimeToFindPreimage.inSeconds - kCounterHtlcDuration.inSeconds) - DateTimeUtils.unixTimeNow) / 60).ceil()} minutes',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white,),),
                    BulletPointCard.textSpan(' left to join the swap.'),
                  ],
                ),
              ),
              RichText(
                text: BulletPointCard.textSpan(
                  'The counterparty will have ',
                  children: <TextSpan>[
                    TextSpan(
                        text: '~${kCounterHtlcDuration.inHours} hour',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white,),),
                    BulletPointCard.textSpan(' to complete the swap.'),
                  ],
                ),
              ),
              RichText(
                text: BulletPointCard.textSpan(
                  'You can reclaim your funds if the counterparty fails to complete the swap. ',
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),
        if (_safeExpirationTime != null) Column(children: <Widget>[
                Visibility(
                  visible:
                      !isTrustedToken(tokenToReceive.tokenStandard.toString()),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ImportantTextContainer(
                      text:
                          '''You are receiving a token that is not in your favorites. '''
                          '''Please verify that the token standard is correct: ${tokenToReceive.tokenStandard}''',
                      isSelectable: true,
                    ),
                  ),
                ),
                _getJoinSwapViewModel(tokenToReceive),
              ],) else const ImportantTextContainer(
                text:
                    'Cannot join swap. The swap will expire too soon for a safe swap.',
                showBorder: true,
              ),
      ],
    );
  }

  ViewModelBuilder<JoinHtlcSwapBloc> _getJoinSwapViewModel(Token tokenToReceive) {
    return ViewModelBuilder<JoinHtlcSwapBloc>.reactive(
      onViewModelReady: (JoinHtlcSwapBloc model) {
        model.stream.listen(
          (HtlcSwap? event) async {
            if (event is HtlcSwap) {
              widget.onJoinedSwap.call(event.id);
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
      builder: (_, JoinHtlcSwapBloc model, __) => _getJoinSwapButton(model, tokenToReceive),
      viewModelBuilder: JoinHtlcSwapBloc.new,
    );
  }

  Widget _getJoinSwapButton(JoinHtlcSwapBloc model, Token tokenToReceive) {
    return InstructionButton(
      text: 'Join swap',
      instructionText: 'Input an amount to send',
      loadingText: 'Sending transaction',
      isEnabled: _isInputValid(),
      isLoading: _isLoading,
      onPressed: () => _onJoinButtonPressed(model, tokenToReceive),
    );
  }

  Future<void> _onJoinButtonPressed(
      JoinHtlcSwapBloc model, Token tokenToReceive,) async {
    setState(() {
      _isLoading = true;
    });
    model.joinHtlcSwap(
        initialHtlc: _initialHltc!,
        fromToken: _selectedToken,
        toToken: tokenToReceive,
        fromAmount:
            _amountController.text.extractDecimals(_selectedToken.decimals),
        swapType: P2pSwapType.native,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        counterHtlcExpirationTime: _safeExpirationTime!,);
  }

  int? _calculateSafeExpirationTime(int initialHtlcExpiration) {
    final Duration minNeededRemainingTime =
        kMinSafeTimeToFindPreimage + kCounterHtlcDuration;
    final int now = DateTimeUtils.unixTimeNow;
    final Duration remaining = Duration(seconds: initialHtlcExpiration - now);
    return remaining >= minNeededRemainingTime
        ? now + kCounterHtlcDuration.inSeconds
        : null;
  }

  Widget _getExchangeRateWidget(Token tokenToReceive) {
    return ExchangeRateWidget(
        fromAmount:
            _amountController.text.extractDecimals(_selectedToken.decimals),
        fromDecimals: _selectedToken.decimals,
        fromSymbol: _selectedToken.symbol,
        toAmount: _initialHltc!.amount,
        toDecimals: tokenToReceive.decimals,
        toSymbol: tokenToReceive.symbol,);
  }

  bool _isInputValid() => _isAmountValid;

  bool _isHashValid() =>
      InputValidators.checkHash(_depositIdController.text) == null;
}
