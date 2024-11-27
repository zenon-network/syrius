import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'infinite_scroll_table_cell.dart';

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
class InfiniteScrollTable<T> extends StatefulWidget {
  /// Creates a new instance.
  const InfiniteScrollTable({
    required this.items,
    required this.hasReachedMax,
    required this.generateRowCells,
    required this.onScrollReachedBottom,
    required this.headerColumns,
    super.key,
  });

  final List<InfiniteScrollTableHeaderColumn> headerColumns;
  final List<Widget> Function(T, bool) generateRowCells;
  final VoidCallback onScrollReachedBottom;
  final List<T> items;
  final bool hasReachedMax;

  @override
  State createState() => _InfiniteScrollTableState<T>();
}

class _InfiniteScrollTableState<T> extends State<InfiniteScrollTable<T>> {
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
        SliverList.separated(
          separatorBuilder: (_, __) => const Divider(
            thickness: 0.75,
          ),
          itemCount: widget.items.length + 1,
          itemBuilder: (BuildContext context, int index) {
            final Widget lastChild = widget.hasReachedMax
                ? SyriusErrorWidget(context.l10n.noItemsFound)
                : const SyriusLoadingWidget();

            return index == widget.items.length
                ? lastChild
                : _getTableRow(
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

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
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
