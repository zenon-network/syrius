import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A table for displaying a large set of items
///
/// It should receive an [onScrollReachedBottom] callback that is triggered
/// when the user scrolls to the bottom of the list. The callback should load
/// the next batch of items.
///
/// There is the case that the first batch can fit inside the view port of the
/// widget, without any need of scrolling. These scenario will block the
/// automatic loading of the next batches, because the [ScrollController]
/// listener won't be triggered. The [onScrollReachedBottom] callback is called
/// after the widget has finished rendering in order to immediately fetch more
/// items, if possible, so that the scroll actives
class NewInfiniteScrollTable<T> extends StatefulWidget {
  /// Creates a new instance.
  const NewInfiniteScrollTable({
    required this.items,
    required this.hasReachedMax,
    required this.generateRowCells,
    required this.onScrollReachedBottom,
    required this.headerColumns,
    this.onRowTappedCallback,
    super.key,
  });

  final List<NewInfiniteScrollTableHeaderColumn> headerColumns;
  final List<Widget> Function(T, bool) generateRowCells;
  final void Function(int index)? onRowTappedCallback;
  final VoidCallback onScrollReachedBottom;
  final List<T> items;
  final bool hasReachedMax;

  @override
  State createState() => _NewInfiniteScrollTableState<T>();
}

class _NewInfiniteScrollTableState<T> extends State<NewInfiniteScrollTable<T>> {
  int? _selectedRowIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !widget.hasReachedMax) {
        if (_scrollController.position.maxScrollExtent == 0) {
          widget.onScrollReachedBottom.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SyriusErrorWidget(context.l10n.noItemsFound);
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        PinnedHeaderSliver(
          child: _Header(columns: widget.headerColumns),
        ),
        SliverList.builder(
          itemCount: widget.items.length + 1,
          itemBuilder: (BuildContext context, int index) {
            // TODO(maznnwell): localize
            final Widget lastChild = widget.hasReachedMax
                ? SyriusErrorWidget(context.l10n.noItemsFound)
                : const SyriusLoadingWidget();

            return index == widget.items.length ? lastChild : _getTableRow(
              widget.items[index],
              index,
            );
          },
        ),
      ],
    );
  }

  void _onScroll() {
    if (_isBottom) {
      widget.onScrollReachedBottom.call();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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
                ? const BorderSide(
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
}

class _Header extends StatelessWidget {
  const _Header({required this.columns});

  final List<Widget> columns;

  @override
  Widget build(BuildContext context) {
    // The content is scrolled under the header, hence we need to cover it up
    final Color background =
        context.isDarkMode ? AppColors.darkPrimary : Colors.white;

    return ColoredBox(
      color: background,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
              ),
              child: Row(
                children: columns,
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class NewInfiniteScrollTableHeaderColumn extends StatelessWidget {
  const NewInfiniteScrollTableHeaderColumn({
    required this.columnName,
    this.onSortArrowsPressed,
    this.flex = 1,
    super.key,
  });

  final String columnName;
  final Function(String)? onSortArrowsPressed;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        children: <Widget>[
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
              child: const Icon(
                Entypo.select_arrows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewInfiniteScrollTableCell extends StatelessWidget {
  const NewInfiniteScrollTableCell(
    this.child, {
    this.flex = 1,
    super.key,
  });

  factory NewInfiniteScrollTableCell.withMarquee(
    String text, {
    Key? key,
    bool showCopyToClipboardIcon = true,
    TextStyle? textStyle,
    Color textColor = AppColors.subtitleColor,
    int flex = 1,
  }) =>
      NewInfiniteScrollTableCell(
        Row(
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
        ),
        flex: flex,
        key: key,
      );

  factory NewInfiniteScrollTableCell.withText(
    BuildContext context,
    String text, {
    Key? key,
    bool showCopyToClipboardIcon = false,
    TextStyle? textStyle,
    Color textColor = AppColors.subtitleColor,
    TextAlign textAlign = TextAlign.start,
    int flex = 1,
  }) =>
      NewInfiniteScrollTableCell(
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                text,
                textAlign: textAlign,
                style: textStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                        ),
              ),
            ),
            Visibility(
              visible: showCopyToClipboardIcon,
              child: Row(
                children: <Widget>[
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
        ),
        flex: flex,
        key: key,
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
