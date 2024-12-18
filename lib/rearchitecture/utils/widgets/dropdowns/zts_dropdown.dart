import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ZtsDropdown extends StatelessWidget {
  const ZtsDropdown({
    required List<Token> availableTokens,
    required void Function(Token) onChangeCallback,
    required Token selectedToken,
    super.key,
  })  : _onChangeCallback = onChangeCallback,
        _availableTokens = availableTokens,
        _selectedToken = selectedToken;

  final void Function(Token) _onChangeCallback;
  final Token _selectedToken;
  final List<Token> _availableTokens;

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry<Token>> entries = _availableTokens
        .map(
          (Token token) => DropdownMenuEntry<Token>(
            label: token.name,
            style: MenuItemButton.styleFrom(
              foregroundColor: ColorUtils.getTokenColor(token.tokenStandard),
            ),
            value: token,
          ),
        )
        .toList();

    final Color color = ColorUtils.getTokenColor(_selectedToken.tokenStandard);

    return DropdownMenu<Token>(
      expandedInsets: EdgeInsets.zero,
      initialSelection: _selectedToken,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
      ),
      dropdownMenuEntries: entries,
      onSelected: (Token? token) {
        if (token != null) {
          _onChangeCallback(token);
        }
      },
      requestFocusOnTap: false,
      textStyle: TextStyle(
        color: color,
      ),
      trailingIcon: Icon(
        SimpleLineIcons.arrow_down,
        size: 10,
        color: color,
      ),
    );
  }
}
