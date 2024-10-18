import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CustomTable<T> extends StatefulWidget {

  const CustomTable({
    required this.items,
    required this.generateRowCells,
    this.headerColumns,
    this.onShowMoreButtonPressed,
    this.onRowTappedCallback,
    super.key,
  });
  final List<T>? items;
  final List<CustomHeaderColumn>? headerColumns;
  final List<Widget> Function(T, bool) generateRowCells;
  final VoidCallback? onShowMoreButtonPressed;
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
      children: [
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
                  ? _getRows() + [_getShowMoreButton()]
                  : _getRows(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _getRows() => widget.items!
      .map(
        (e) => _getTableRow(
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
              [
                const SizedBox(
                  width: 20,
                ),
              ],
            ) +
            (widget.headerColumns ?? []),
      ),
    );
  }

  Widget _getTableRow(dynamic item, int indexOfRow) {
    final isSelected = _selectedRowIndex == indexOfRow;

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
                [
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

class CustomHeaderColumn extends StatelessWidget {

  const CustomHeaderColumn({
    required this.columnName,
    this.onSortArrowsPressed,
    this.contentAlign = MainAxisAlignment.start,
    this.flex = 1,
    super.key,
  });
  final String columnName;
  final Function(String)? onSortArrowsPressed;
  final MainAxisAlignment contentAlign;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: contentAlign,
        children: [
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

class CustomTableCell extends StatelessWidget {

  const CustomTableCell(
    this.child, {
    this.flex = 1,
    super.key,
  });

  CustomTableCell.tooltipWithMarquee(
    Address address, {
    super.key,
    TextStyle? textStyle,
    this.flex = 1,
    Color textColor = AppColors.subtitleColor,
  })  : child = Row(
          children: [
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
            CopyToClipboardIcon(
              address.toString(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(
              width: 10,
            ),
          ],
        );

  CustomTableCell.withMarquee(
    String text, {
    super.key,
    bool showCopyToClipboardIcon = true,
    TextStyle? textStyle,
    this.flex = 1,
    Color textColor = AppColors.subtitleColor,
  })  : child = Row(
          children: [
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
                children: [
                  CopyToClipboardIcon(
                    text,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ],
        );

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
          children: [
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
                children: [
                  CopyToClipboardIcon(
                    address.toString(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ],
        );

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
          children: [
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
                children: [
                  CopyToClipboardIcon(
                    text,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ],
        );
  final Widget child;
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
