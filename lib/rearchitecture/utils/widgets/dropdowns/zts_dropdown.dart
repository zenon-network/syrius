import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A dropdown for all the network assets - tokens and coins
class ZtsDropdown extends StatefulWidget {
  /// Creates a new instance.
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
  State<ZtsDropdown> createState() => _ZtsDropdownState();
}

class _ZtsDropdownState extends State<ZtsDropdown> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry<Token>> entries = widget._availableTokens.map(
      (Token token) {
        final String labelSuffix = token.isCoin
            ? context.l10n.coin
            : token.tokenStandard.toString().short;

        final String label = '${token.name} - $labelSuffix';

        final Widget znnIcon = Image(
          color: ColorUtils.getTokenColor(token.tokenStandard),
          fit: BoxFit.contain,
          height: 15,
          image: const AssetImage(
            'assets/images/qr_code_child_image_znn_cut.png',
          ),
        );

        final Widget? trailingIcon = token.isCoin ? znnIcon : null;

        return DropdownMenuEntry<Token>(
          labelWidget: Row(
            children: <Widget>[
              Text(label),
              if (trailingIcon != null) Row(
                children: <Widget>[
                  kHorizontalGap8,
                  trailingIcon,
                ],
              ),
            ],
          ),
          label: label,
          style: MenuItemButton.styleFrom(
            foregroundColor: ColorUtils.getTokenColor(token.tokenStandard),
          ),
          value: token,
        );
      },
    ).toList();

    final Color color = ColorUtils.getTokenColor(
      widget._selectedToken.tokenStandard,
    );

    return DropdownMenu<Token>(
      controller: _searchController,
      expandedInsets: EdgeInsets.zero,
      initialSelection: widget._selectedToken,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
      ),
      leadingIcon: Icon(
        Icons.search,
        color: color,
      ),
      dropdownMenuEntries: entries,
      menuHeight: kDropdownMenuHeight,
      onSelected: (Token? token) {
        if (token != null) {
          widget._onChangeCallback(token);
        }
      },
      searchCallback: _searchCallback,
      textStyle: TextStyle(
        color: color,
      ),
      trailingIcon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: color,
      ),
    );
  }

  int? _searchCallback(List<DropdownMenuEntry<Token>> entries, String query) {
    final String searchText = query.toLowerCase();
    if (searchText.isEmpty) {
      return null;
    }
    final int index = entries.indexWhere(
      (DropdownMenuEntry<Token> entry) => _matchTest(entry, searchText),
    );

    return index != -1 ? index : null;
  }

  bool _matchTest(DropdownMenuEntry<Token> entry, String searchText) =>
      entry.label.toLowerCase().contains(searchText) ||
      entry.value.symbol.toLowerCase().contains(searchText) ||
      entry.value.tokenStandard.toString().toLowerCase().contains(searchText);
}
