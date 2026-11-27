import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Generic scrollable data table with selectable rows and optional pagination.
class CustomTable<T> extends StatefulWidget {
  /// Creates a [CustomTable].
  const CustomTable({
    required this.items,
    required this.generateRowCells,
    this.headerColumns,
    this.onShowMoreButtonPressed,
    this.onRowTappedCallback,
    super.key,
  });

  /// Items rendered as table rows.
  final List<T>? items;

  /// Optional column headers displayed above the table rows.
  final List<CustomHeaderColumn>? headerColumns;

  /// Builder that returns row cells for an item and its selection state.
  // Preserves the existing public callback signature for external callers.
  // ignore: avoid_positional_boolean_parameters
  final List<Widget> Function(T, bool) generateRowCells;

  /// Optional callback invoked when the "Show more" footer button is pressed.
  final VoidCallback? onShowMoreButtonPressed;

  /// Optional callback invoked with the row index when a row is tapped.
  final void Function(int index)? onRowTappedCallback;

  @override
  State createState() => _CustomTableState<T>();
}

class _CustomTableState<T> extends State<CustomTable<T>> {
  final ScrollController _scrollController = ScrollController();

  int? _selectedRowIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Visibility(
          visible: widget.headerColumns != null,
          child: _getTableHeader(),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              shrinkWrap: true,
              children: widget.onShowMoreButtonPressed != null
                  ? _getRows() + <Widget>[_getShowMoreButton()]
                  : _getRows(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _getRows() => widget.items!
      .map(
        (T e) => _getTableRow(
          e,
          widget.items!.indexOf(e),
        ),
      )
      .toList();

  Container _getTableHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color!,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      child: Row(
        children: List<Widget>.from(
              <SizedBox>[
                const SizedBox(
                  width: 20,
                ),
              ],
            ) +
            (widget.headerColumns ?? <Widget>[]),
      ),
    );
  }

  Widget _getTableRow(dynamic item, int indexOfRow) {
    final bool isSelected = _selectedRowIndex == indexOfRow;

    return InkWell(
      onTap: () {
        widget.onRowTappedCallback?.call(indexOfRow);
        setState(() {
          if (_selectedRowIndex != indexOfRow) {
            _selectedRowIndex = indexOfRow;
          } else {
            _selectedRowIndex = null;
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          border: Border(
            top: indexOfRow != 0
                ? BorderSide(
                    color: Theme.of(context).dividerTheme.color!,
                    width: 0.75,
                  )
                : BorderSide.none,
            left: isSelected
                ? const BorderSide(
                    color: AppColors.znnColor,
                    width: 2,
                  )
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 15,
        ),
        child: Row(
          children: List<Widget>.from(
                <SizedBox>[
                  const SizedBox(
                    width: 20,
                  ),
                ],
              ) +
              widget.generateRowCells(item, isSelected),
        ),
      ),
    );
  }

  Widget _getShowMoreButton() {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white12,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      onPressed: widget.onShowMoreButtonPressed,
      child: Text(
        'Show more',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Header column cell for a [CustomTable] with optional sort arrows.
class CustomHeaderColumn extends StatelessWidget {
  /// Creates a [CustomHeaderColumn].
  const CustomHeaderColumn({
    required this.columnName,
    this.onSortArrowsPressed,
    this.contentAlign = MainAxisAlignment.start,
    this.flex = 1,
    super.key,
  });

  /// Display title of the column.
  final String columnName;

  /// Optional callback invoked with [columnName] when sort arrows are tapped.
  final Function(String)? onSortArrowsPressed;

  /// Horizontal alignment of the column header content.
  final MainAxisAlignment contentAlign;

  /// Flex factor controlling the column width within the header row.
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: contentAlign,
        children: <Widget>[
          Text(
            columnName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Visibility(
            visible: onSortArrowsPressed != null,
            child: InkWell(
              onTap: () => onSortArrowsPressed!(columnName),
              child: Icon(
                Entypo.select_arrows,
                size: 15,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flexible row cell widget used inside a [CustomTable].
class CustomTableCell extends StatelessWidget {
  /// Creates a [CustomTableCell] wrapping an arbitrary [child] widget.
  const CustomTableCell(
    this.child, {
    this.flex = 1,
    super.key,
  });

  /// Creates a [CustomTableCell] showing an address label with marquee and
  /// tooltip.
  CustomTableCell.tooltipWithMarquee(
    Address address, {
    super.key,
    TextStyle? textStyle,
    this.flex = 1,
    Color textColor = AppColors.subtitleColor,
  })  : child = Row(
          children: <Widget>[
            Expanded(
              child: Tooltip(
                message: address.toString(),
                child: Container(
                  margin: const EdgeInsets.only(
                    right: 10,
                  ),
                  child: Marquee(
                    child: Text(
                      kAddressLabelMap[address.toString()]!,
                      style: textStyle ??
                          TextStyle(
                            color: textColor,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            CopyToClipboardButton(
              address.toString(),
            ),
            const SizedBox(
              width: 10,
            ),
          ],
        );

  /// Creates a [CustomTableCell] showing scrolling marquee [text].
  CustomTableCell.withMarquee(
    String text, {
    super.key,
    bool showCopyToClipboardIcon = true,
    TextStyle? textStyle,
    this.flex = 1,
    Color textColor = AppColors.subtitleColor,
  })  : child = Row(
          children: <Widget>[
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(
                  right: 10,
                ),
                child: Marquee(
                  child: Text(
                    text,
                    style: textStyle ??
                        TextStyle(
                          color: textColor,
                          fontSize: 12,
                        ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: showCopyToClipboardIcon,
              child: Row(
                children: <Widget>[
                  CopyToClipboardButton(
                    text,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ],
        );

  /// Creates a [CustomTableCell] showing an address label with a tooltip.
  CustomTableCell.tooltipWithText(
    BuildContext context,
    Address? address, {
    super.key,
    bool showCopyToClipboardIcon = false,
    TextStyle? textStyle,
    this.flex = 1,
    Color textColor = AppColors.subtitleColor,
    TextAlign textAlign = TextAlign.start,
  })  : child = Row(
          children: <Widget>[
            Expanded(
              child: Tooltip(
                message: address.toString(),
                child: Text(
                  ZenonAddressUtils.getLabel(address.toString()),
                  textAlign: textAlign,
                  style: textStyle ??
                      Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: textColor,
                          ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Visibility(
              visible: showCopyToClipboardIcon,
              child: Row(
                children: <Widget>[
                  CopyToClipboardButton(
                    address.toString(),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ],
        );

  /// Creates a [CustomTableCell] displaying plain [text].
  CustomTableCell.withText(
    BuildContext context,
    String text, {
    super.key,
    bool showCopyToClipboardIcon = false,
    TextStyle? textStyle,
    this.flex = 1,
    Color textColor = AppColors.subtitleColor,
    TextAlign textAlign = TextAlign.start,
  })  : child = Row(
          children: <Widget>[
            Expanded(
              child: Text(
                text,
                textAlign: textAlign,
                style: textStyle ??
                    Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: textColor,
                        ),
              ),
            ),
            Visibility(
              visible: showCopyToClipboardIcon,
              child: Row(
                children: <Widget>[
                  CopyToClipboardButton(
                    text,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ],
        );

  /// Widget rendered inside the flexible cell.
  final Widget child;

  /// Flex factor controlling the cell width within its row.
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      fit: FlexFit.tight,
      child: child,
    );
  }
}
