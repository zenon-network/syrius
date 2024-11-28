import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'infinite_scroll_table_column_type.dart';

part 'infinite_scroll_table_cell.dart';

part 'infinite_scroll_table_column.dart';

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
    required this.columns,
    super.key,
  });

  /// The columns that will the organized in an fixed header
  final List<InfiniteScrollTableColumnType> columns;

  /// Function that takes in an item and returns the cells consisting the row
  final List<Widget> Function(T) generateRowCells;

  /// Callback to be executed when the bottom of the table was reached.
  final VoidCallback onScrollReachedBottom;

  /// List of items that constitutes the rows.
  final List<T> items;

  /// Whether there are still items that can be fetched.
  final bool hasReachedMax;

  @override
  State createState() => _InfiniteScrollTableState<T>();
}

class _InfiniteScrollTableState<T> extends State<InfiniteScrollTable<T>> {
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
          child: _Header(columns: widget.columns),
        ),
        SliverList.separated(
          separatorBuilder: (_, __) => const Divider(
            thickness: 0.75,
          ),
          itemCount: widget.items.length + 1,
          itemBuilder: (BuildContext context, int index) {
            final Widget lastChild = widget.hasReachedMax
                ? SyriusErrorWidget(context.l10n.noMoreItems)
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

  Widget _getTableRow(T item, int indexOfRow) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: kInfiniteTableLeftPadding,
      ),
      child: Row(
        children: widget.generateRowCells(item),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.columns});

  final List<InfiniteScrollTableColumnType> columns;

  @override
  Widget build(BuildContext context) {
    // The content is scrolled under the header, hence we need to cover it up
    final Color background =
        context.isDarkMode ? AppColors.darkPrimary : Colors.white;

    final List<Widget> children = List<Widget>.generate(
      columns.length,
      (int index) {
        final InfiniteScrollTableColumnType column = columns[index];

        final int flex = column.flex;

        final String name = column.name(context: context);

        return InfiniteScrollTableColumn(
          name: name,
          flex: flex,
        );
      },
    );

    return ColoredBox(
      color: background,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.only(
                left: kInfiniteTableLeftPadding,
              ),
              child: Row(
                children: children,
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
