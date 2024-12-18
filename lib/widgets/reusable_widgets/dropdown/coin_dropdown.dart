import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CoinDropdown extends StatelessWidget {
  const CoinDropdown(
    this._availableTokens,
    this._selectedToken,
    this._onChangeCallback, {
    super.key,
  });

  final Function(Token?) _onChangeCallback;
  final Token _selectedToken;
  final List<Token?> _availableTokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kAmountSuffixHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kAmountSuffixRadius),
        color: ColorUtils.getTokenColor(_selectedToken.tokenStandard),
      ),
      child: Tooltip(
        message: '${_selectedToken.tokenStandard}',
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Token>(
              value: _selectedToken,
              isDense: true,
              selectedItemBuilder: (BuildContext context) {
                return _availableTokens
                    .map<Widget>(
                      (Token? e) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          children: <Widget>[
                            Text(
                              e!.symbol,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList();
              },
              items: _availableTokens.map(
                (Token? token) {
                  return DropdownMenuItem<Token>(
                    value: token,
                    child: Text(
                      token!.symbol,
                      style: TextStyle(
                        color:
                            _selectedToken == token ? AppColors.znnColor : null,
                      ),
                    ),
                  );
                },
              ).toList(),
              onChanged: _onChangeCallback,
            ),
          ),
        ),
      ),
    );
  }
}
