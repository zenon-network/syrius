import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReceiveMediumCard extends StatefulWidget {

  const ReceiveMediumCard({required this.onExpandClicked, super.key});
  final VoidCallback onExpandClicked;

  @override
  State<ReceiveMediumCard> createState() => _ReceiveMediumCardState();
}

class _ReceiveMediumCardState extends State<ReceiveMediumCard> {
  final TextEditingController _transferAddrController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey();

  String? _selectedSelfAddress = kSelectedAddress;

  Token _selectedToken = kDualCoin.first;

  final List<Token> _tokens = <Token>[];

  final GlobalKey<FormState> _amountKey = GlobalKey();

  final Box _recipientAddressBox = Hive.box(kRecipientAddressBox);

  final TokensBloc _tokensBloc = TokensBloc();

  @override
  void initState() {
    _initAddressController();
    _tokensBloc.getDataAsync();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: context.l10n.receive,
      titleFontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
      description: context.l10n.manageReceivingFunds,
      childBuilder: _getTokensStreamBuilder,
    );
  }

  Widget _getTokensStreamBuilder() {
    return StreamBuilder<List<Token>?>(
        stream: _tokensBloc.stream,
        builder: (_, AsyncSnapshot<List<Token>?> snapshot) {
          if (snapshot.hasError) {
            return SyriusErrorWidget(snapshot.error!);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getWidgetBody(context, snapshot.data!);
            }
            return const SyriusLoadingWidget();
          }
          return const SyriusLoadingWidget();
        },);
  }

  Widget _getWidgetBody(BuildContext context, List<Token> tokens) {
    _initTokens(tokens);

    return Container(
      margin: const EdgeInsets.only(
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SizedBox(
                  width: 20,
                ),
                ReceiveQrImage(
                  data: _getQrString(),
                  size: 110,
                  tokenStandard: _selectedToken.tokenStandard,
                  context: context,
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _getDefaultAddressDropdown(),
                          ),
                          CopyToClipboardIcon(
                            _selectedSelfAddress,
                            iconColor: AppColors.darkHintTextColor,
                          ),
                        ],
                      ),
                      kVerticalSpacing,
                      Form(
                        key: _amountKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: InputField(
                          validator: (String? value) => InputValidators.correctValue(
                              value,
                              kBigP255m1,
                              _selectedToken.decimals,
                              BigInt.zero,),
                          onChanged: (String value) => setState(() {}),
                          inputFormatters:
                              FormatUtils.getAmountTextInputFormatters(
                            _amountController.text,
                          ),
                          controller: _amountController,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              _getCoinDropdown(),
                              const SizedBox(
                                width: 15,
                              ),
                            ],
                          ),
                          hintText: context.l10n.amount,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 35,
            ),
            Row(
              children: <Widget>[
                TransferToggleCardSizeButton(
                  onPressed: widget.onExpandClicked,
                  iconData: Icons.navigate_before,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getQrString() {
    return '${_selectedToken.symbol.toLowerCase()}:'
        '$_selectedSelfAddress?zts=${_selectedToken.tokenStandard}'
        '&amount=${_getAmount()}';
  }

  BigInt _getAmount() {
    try {
      return _amountController.text.extractDecimals(_selectedToken.decimals);
    } catch (e) {
      return BigInt.zero;
    }
  }

  void _initAddressController() {
    if (_recipientAddressBox.isNotEmpty) {
      _transferAddrController.text = _recipientAddressBox.getAt(0);
    }
  }

  Widget _getDefaultAddressDropdown() {
    return AddressesDropdown(
      _selectedSelfAddress,
      (String? value) => setState(() {
        _selectedSelfAddress = value;
      }),
    );
  }

  Widget _getCoinDropdown() => CoinDropdown(
        _tokens.toList(),
        _selectedToken,
        (Token? value) {
          if (_selectedToken != value) {
            setState(
              () {
                _selectedToken = value!;
              },
            );
          }
        },
      );

  void _initTokens(List<Token> tokens) {
    if (_tokens.isNotEmpty) {
      _tokens.clear();
    }
    _tokens.addAll(kDualCoin);
    for (final Token element in tokens) {
      if (!_tokens.contains(element)) {
        _tokens.add(element);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transferAddrController.dispose();
    _tokensBloc.dispose();
    super.dispose();
  }
}
