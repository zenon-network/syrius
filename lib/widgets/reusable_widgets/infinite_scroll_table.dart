import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class InfiniteScrollTable<T> extends StatefulWidget {
  final List<InfiniteScrollTableHeaderColumn>? headerColumns;
  final List<Widget> Function(T, bool) generateRowCells;
  final void Function(int index)? onRowTappedCallback;
  final InfiniteScrollBloc<T> bloc;
  final bool disposeBloc;

  const InfiniteScrollTable({
    required this.bloc,
    required this.generateRowCells,
    this.headerColumns,
    this.onRowTappedCallback,
    this.disposeBloc = true,
    Key? key,
  }) : super(key: key);

  @override
  State createState() => _InfiniteScrollTableState<T>();
}

class _InfiniteScrollTableState<T> extends State<InfiniteScrollTable<T>> {
  final ScrollController _scrollController = ScrollController();
  final PagingController<int, T> _pagingController = PagingController(
    firstPageKey: 0,
  );
  late StreamSubscription _blocListingStateSubscription;

  int? _selectedRowIndex;

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      widget.bloc.onPageRequestSink.add(pageKey);
    });
    _blocListingStateSubscription =
        widget.bloc.onNewListingState.listen((listingState) {
      _pagingController.value = PagingState(
        nextPageKey: listingState.nextPageKey,
        error: listingState.error,
        itemList: listingState.itemList,
      );
    });
    super.initState();
  }

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
            child: PagedListView<int, T>(
              scrollController: _scrollController,
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<T>(
                itemBuilder: (_, item, index) => _getTableRow(
                  item,
                  index,
                ),
                firstPageProgressIndicatorBuilder: (_) =>
                    const SyriusLoadingWidget(),
                newPageProgressIndicatorBuilder: (_) =>
                    const SyriusLoadingWidget(),
                noMoreItemsIndicatorBuilder: (_) =>
                    const SyriusErrorWidget('No more items'),
                noItemsFoundIndicatorBuilder: (_) =>
                    const SyriusErrorWidget('No items found'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<T>? getTableItems() => _pagingController.value.itemList;

  Container _getTableHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color!,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 15.0,
      ),
      child: Row(
        children: List<Widget>.from(
              [
                const SizedBox(
                  width: 20.0,
                )
              ],
            ) +
            (widget.headerColumns ?? []),
      ),
    );
  }

  Widget _getTableRow(dynamic item, int indexOfRow) {
    bool isSelected = _selectedRowIndex == indexOfRow;

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
                    width: 2.0,
                  )
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 15.0,
        ),
        child: Row(
          children: List<Widget>.from(
                [
                  const SizedBox(
                    width: 20.0,
                  )
                ],
              ) +
              widget.generateRowCells(item, isSelected),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _blocListingStateSubscription.cancel();
    if (widget.disposeBloc) {
      widget.bloc.dispose();
    }
    super.dispose();
  }
}

class InfiniteScrollTableHeaderColumn extends StatelessWidget {
  final String columnName;
  final Function(String)? onSortArrowsPressed;
  final MainAxisAlignment contentAlign;
  final int flex;

  const InfiniteScrollTableHeaderColumn({
    required this.columnName,
    this.onSortArrowsPressed,
    this.contentAlign = MainAxisAlignment.start,
    this.flex = 1,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: contentAlign,
        children: [
          Expanded(
            child: Text(
              columnName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Visibility(
            visible: false,
            child: InkWell(
              onTap: () => onSortArrowsPressed!(columnName),
              child: Icon(
                Entypo.select_arrows,
                size: 15.0,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class InfiniteScrollTableCell extends StatelessWidget {
  final Widget child;
  final int flex;

  const InfiniteScrollTableCell(
    this.child, {
    this.flex = 1,
    Key? key,
  }) : super(key: key);

  factory InfiniteScrollTableCell.tooltipWithMarquee(
    Address address, {
    Key? key,
    TextStyle? textStyle,
    Color textColor = AppColors.subtitleColor,
    int flex = 1,
  }) =>
      InfiniteScrollTableCell(
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: address.toString(),
                child: Container(
                  margin: const EdgeInsets.only(
                    right: 10.0,
                  ),
                  child: Marquee(
                    child: Text(
                      kAddressLabelMap[address.toString()]!,
                      style: textStyle ??
                          TextStyle(
                            color: textColor,
                            fontSize: 12.0,
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
              width: 10.0,
            ),
          ],
        ),
        flex: flex,
        key: key,
      );

  factory InfiniteScrollTableCell.withMarquee(
    String text, {
    Key? key,
    bool showCopyToClipboardIcon = true,
    TextStyle? textStyle,
    Color textColor = AppColors.subtitleColor,
    int flex = 1,
  }) =>
      InfiniteScrollTableCell(
        Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(
                  right: 10.0,
                ),
                child: Marquee(
                  child: Text(
                    text,
                    style: textStyle ??
                        TextStyle(
                          color: textColor,
                          fontSize: 12.0,
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
                    width: 10.0,
                  ),
                ],
              ),
            ),
          ],
        ),
        flex: flex,
        key: key,
      );

  factory InfiniteScrollTableCell.tooltipWithText(
    BuildContext context,
    Address? address, {
    Key? key,
    bool showCopyToClipboardIcon = false,
    TextStyle? textStyle,
    Color textColor = AppColors.subtitleColor,
    TextAlign textAlign = TextAlign.start,
    int flex = 1,
  }) =>
      InfiniteScrollTableCell(
        Row(
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
                    width: 10.0,
                  ),
                ],
              ),
            ),
          ],
        ),
        flex: flex,
        key: key,
      );

  factory InfiniteScrollTableCell.withText(
    BuildContext context,
    String text, {
    Key? key,
    bool showCopyToClipboardIcon = false,
    TextStyle? textStyle,
    Color textColor = AppColors.subtitleColor,
    TextAlign textAlign = TextAlign.start,
    int flex = 1,
  }) =>
      InfiniteScrollTableCell(
        Row(
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
                    width: 10.0,
                  ),
                ],
              ),
            ),
          ],
        ),
        flex: flex,
        key: key,
      );

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      fit: FlexFit.tight,
      child: child,
    );
  }
}
