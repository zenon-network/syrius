import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A dropdown for all the network assets - tokens and coins
class ZtsDropdown extends StatefulWidget {
  /// Creates a new instance.
  const ZtsDropdown({
    required this._availableTokens,
    required this._selectedToken,
    this._enabled = true,
    this._label,
    super.key,
  });

  final ValueNotifier<Token> _selectedToken;
  final List<Token> _availableTokens;
  final Widget? _label;
  final bool _enabled;

  @override
  State<ZtsDropdown> createState() => _ZtsDropdownState();
}

class _ZtsDropdownState extends State<ZtsDropdown> {
  Token get _token => widget._selectedToken.value;

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuEntry<Token>> entries = widget._availableTokens.map(
      (Token token) {
        final String labelSuffix = token.isCoin
            ? ''
            : ' (${token.tokenStandard.toString().short})';

        final String label = '${token.symbol} $labelSuffix';

        return DropdownMenuEntry<Token>(
          label: label,
          style: MenuItemButton.styleFrom(
            foregroundColor: ColorUtils.getTokenColor(token.tokenStandard),
          ),
          value: token,
        );
      },
    ).toList();

    final Color color = ColorUtils.getTokenColor(
      _token.tokenStandard,
    );

    return DropdownMenu<Token>(
      enabled: widget._enabled,
      expandedInsets: EdgeInsets.zero,
      initialSelection: _token,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
      ),
      label: widget._label,
      leadingIcon: Icon(
        Icons.search,
        color: color,
      ),
      dropdownMenuEntries: entries,
      menuHeight: kDropdownMenuHeight,
      onSelected: (Token? token) {
        if (token != null) {
          widget._selectedToken.value = token;
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
