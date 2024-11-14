import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReceiveCard extends StatefulWidget {
  const ReceiveCard({
    super.key,
  });

  @override
  State<ReceiveCard> createState() => _ReceiveCardState();
}

class _ReceiveCardState extends State<ReceiveCard> {
  final TextEditingController _transferAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey();

  String _selectedSelfAddress = kSelectedAddress!;

  Token _selectedToken = kDualCoin.first;
  final List<Token> _tokens = <Token>[];

  final Box _recipientAddressBox = Hive.box(kRecipientAddressBox);

  final TokensBloc _tokensBloc = TokensBloc();

  @override
  void initState() {
    super.initState();
    _initAddressController();
    _tokensBloc.getDataAsync();
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
      },
    );
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
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(
                  width: 20,
                ),
                ReceiveQrImage(
                  data: _getQrString(),
                  size: 150,
                  tokenStandard: _selectedToken.tokenStandard,
                  context: context,
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: Column(
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
                      kVerticalGap16,
                      ZtsDropdown(
                        availableTokens: _tokens,
                        onChangeCallback: (Token token) => setState(() {
                          _selectedToken = token;
                        }),
                        selectedToken: _selectedToken,
                      ),
                      kVerticalGap16,
                      InputField(
                        validator: (String? value) =>
                            InputValidators.correctValue(
                          value,
                          kBigP255m1,
                          _selectedToken.decimals,
                          BigInt.zero,
                        ),
                        onChanged: (String value) => setState(() {}),
                        inputFormatters:
                            FormatUtils.getAmountTextInputFormatters(
                          _amountController.text,
                        ),
                        controller: _amountController,
                        hintText: context.l10n.amount,
                      ),
                    ],
                  ),
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
      _transferAddressController.text = _recipientAddressBox.getAt(0);
    }
  }

  Widget _getDefaultAddressDropdown() {
    return NewAddressesDropdown(
      addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      selectedAddress: _selectedSelfAddress,
      onSelectedCallback: (String value) => setState(
        () {
          _selectedSelfAddress = value;
        },
      ),
    );
  }

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
    _transferAddressController.dispose();
    _amountController.dispose();
    _tokensBloc.dispose();
    super.dispose();
  }
}
