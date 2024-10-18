import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/model/basic_dropdown_item.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class BasicDropdown<T> extends StatelessWidget {

  const BasicDropdown(
    this._hint,
    this._selectedValue,
    this._items,
    this.onChangedCallback, {
    super.key,
  });
  final String _hint;
  final BasicDropdownItem<T>? _selectedValue;
  final List<BasicDropdownItem<T>> _items;
  final Function(BasicDropdownItem<T>?)? onChangedCallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BasicDropdownItem<T>>(
          hint: Text(
            _hint,
            style: Theme.of(context).inputDecorationTheme.hintStyle,
          ),
          icon: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 17.5, 0),
            child: Icon(
              SimpleLineIcons.arrow_down,
              size: 10,
              color: _selectedValue != null
                  ? AppColors.znnColor
                  : AppColors.lightSecondary,
            ),
          ),
          value: _selectedValue,
          items: _items.map(
            (BasicDropdownItem<T> item) {
              return DropdownMenuItem<BasicDropdownItem<T>>(
                value: item,
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: _selectedValue == item
                            ? onChangedCallback != null
                                ? AppColors.znnColor
                                : AppColors.lightSecondary
                            : null,
                      ),
                ),
              );
            },
          ).toList(),
          onChanged: onChangedCallback,
        ),
      ),
    );
  }
}
