import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that helps the user generate a QR for requesting funds.
///
/// It has two dropdowns:
/// - one for the address on which the funds will be received.
/// - one for the asset that will be transferred - token or native coin.
///
/// And a [TextField] for inputting the transfer amount.
///
/// This data, destination address, asset and amount, is found in the QR.
class ReceivePopulated extends StatefulWidget {
  /// Creates a new instance.
  const ReceivePopulated({
    required this.assets,
    super.key,
  });

  /// The list of available assets on the network - includes tokens and coins
  final List<Token> assets;

  @override
  State<ReceivePopulated> createState() => _ReceivePopulatedState();
}

class _ReceivePopulatedState extends State<ReceivePopulated> {
  final TextEditingController _amountController = TextEditingController();

  String _selectedSenderAddress = kSelectedAddress!;

  late Token _selectedToken;

  String get _amount => _amountController.text;

  String? get _amountErrorText => InputValidators.correctValue(
        _amount,
        kBigP255m1,
        _selectedToken.decimals,
        BigInt.zero,
      );

  @override
  void initState() {
    super.initState();
    _selectedToken = widget.assets.firstWhere(
      (Token asset) => asset.tokenStandard.toString() == znnTokenStandard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReceiveQrImage(
            data: _getQrString(),
            size: 150,
            tokenStandard: _selectedToken.tokenStandard,
            context: context,
          ),
          kHorizontalGap16,
          Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _getDefaultAddressDropdown(),
                    ),
                    CopyToClipboardButton(
                      _selectedSenderAddress,
                    ),
                  ],
                ),
                kVerticalGap16,
                ZtsDropdown(
                  availableTokens: widget.assets,
                  onChangeCallback: (Token token) => setState(() {
                    _selectedToken = token;
                  }),
                  selectedToken: _selectedToken,
                ),
                kVerticalGap16,
                TextField(
                  decoration: InputDecoration(
                    errorText: _amount.isNotEmpty ? _amountErrorText : null,
                    hintText: context.l10n.amount,
                  ),
                  onChanged: (String value) => setState(() {}),
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _amountController.text,
                  ),
                  controller: _amountController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQrString() {
    return '${_selectedToken.symbol.toLowerCase()}:'
        '$_selectedSenderAddress?zts=${_selectedToken.tokenStandard}'
        '&amount=${_getAmount()}';
  }

  BigInt _getAmount() {
    try {
      return _amountController.text.extractDecimals(_selectedToken.decimals);
    } catch (e) {
      return BigInt.zero;
    }
  }

  Widget _getDefaultAddressDropdown() {
    return NewAddressesDropdown(
      addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      selectedAddress: _selectedSenderAddress,
      onSelectedCallback: (String value) => setState(
        () {
          _selectedSenderAddress = value;
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
