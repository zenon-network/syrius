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

class ReceiveLargeCard extends StatefulWidget {
  final bool? extendIcon;
  final VoidCallback onCollapseClicked;

  const ReceiveLargeCard({
    Key? key,
    this.extendIcon,
    required this.onCollapseClicked,
  }) : super(key: key);

  @override
  State<ReceiveLargeCard> createState() => _ReceiveLargeCardState();
}

class _ReceiveLargeCardState extends State<ReceiveLargeCard> {
  final TextEditingController _transferAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey();
  final GlobalKey<FormState> _amountKey = GlobalKey();

  String? _selectedSelfAddress = kSelectedAddress;

  Token _selectedToken = kDualCoin.first;
  final List<Token> _tokens = [];

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
      title: 'Receive',
      titleFontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
      description: 'Manage receiving funds',
      childBuilder: () => _getTokensStreamBuilder(),
    );
  }

  Widget _getTokensStreamBuilder() {
    return StreamBuilder<List<Token>?>(
      stream: _tokensBloc.stream,
      builder: (_, snapshot) {
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
        right: 20.0,
        top: 20.0,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(
                  width: 20.0,
                ),
                ReceiveQrImage(
                  data: _getQrString(),
                  size: 150.0,
                  tokenStandard: _selectedToken.tokenStandard,
                  context: context,
                ),
                const SizedBox(
                  width: 20.0,
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            flex: 7,
                            child: Form(
                              key: _amountKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: InputField(
                                validator: InputValidators.validateAmount,
                                onChanged: (value) => setState(() {}),
                                inputFormatters:
                                    FormatUtils.getAmountTextInputFormatters(
                                  _amountController.text,
                                ),
                                controller: _amountController,
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _getCoinDropdown(),
                                    const SizedBox(
                                      width: 15.0,
                                    ),
                                  ],
                                ),
                                hintText: 'Amount',
                              ),
                            ),
                          ),
                        ],
                      ),
                      kVerticalSpacing,
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 7,
                            child: _getDefaultAddressDropdown(),
                          ),
                          CopyToClipboardIcon(
                            _selectedSelfAddress,
                            iconColor: AppColors.darkHintTextColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Visibility(
                  visible: widget.extendIcon!,
                  child: TransferToggleCardSizeButton(
                    onPressed: widget.onCollapseClicked,
                    iconData: Icons.navigate_next,
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
    return '${_selectedToken.symbol.toLowerCase()}:$_selectedSelfAddress?zts='
        '${_selectedToken.tokenStandard}'
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
    return AddressesDropdown(
      _selectedSelfAddress,
      (value) => setState(
        () {
          _selectedToken = kDualCoin.first;
          _selectedSelfAddress = value;
          _tokensBloc.getDataAsync();
        },
      ),
    );
  }

  Widget _getCoinDropdown() => CoinDropdown(
        _tokens,
        _selectedToken,
        (value) {
          if (_selectedToken.tokenStandard != value!.tokenStandard) {
            setState(
              () {
                _selectedToken = value;
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
    for (var element in tokens) {
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
