import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class NewAddressesDropdown extends StatelessWidget {
  const NewAddressesDropdown({
    required List<String> addresses,
    required void Function(String) onSelectedCallback,
    required String selectedAddress,
    super.key,
  })  :
        _addresses = addresses,
        _onSelectedCallback = onSelectedCallback,
        _selectedAddress = selectedAddress;
  final List<String> _addresses;
  final void Function(String) _onSelectedCallback;
  final String _selectedAddress;

  @override
  Widget build(BuildContext context) {
    const Color color = AppColors.znnColor;

    final List<DropdownMenuEntry<String>> entries = _addresses
        .map(
          (String address) => DropdownMenuEntry<String>(
        label: kAddressLabelMap[address]!,
        style: MenuItemButton.styleFrom(
          foregroundColor: address == _selectedAddress ? color : null,
        ),
        value: address,
      ),
    )
        .toList();

    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      initialSelection: _selectedAddress,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
      ),
      dropdownMenuEntries: entries,
      onSelected: (String? address) {
        if (address != null) {
          _onSelectedCallback(address);
        }
      },
      requestFocusOnTap: false,
      textStyle: const TextStyle(
        color: color,
      ),
      trailingIcon: const Icon(
        SimpleLineIcons.arrow_down,
        size: 10,
        color: color,
      ),
    );
  }
}