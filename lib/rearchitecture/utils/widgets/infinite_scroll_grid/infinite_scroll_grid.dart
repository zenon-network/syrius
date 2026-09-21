import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A grid for displaying a large, paginated set of items.
///
/// When the user approaches the bottom of the grid, [onScrollReachedBottom]
/// is called so the next batch of items can be loaded. The callback is also
/// called when the current items do not fill the viewport.
class InfiniteScrollGrid<T> extends StatefulWidget {
  /// Creates a new instance.
  const InfiniteScrollGrid({
    required this.items,
    required this.hasReachedMax,
    required this.itemBuilder,
    required this.onScrollReachedBottom,
    required this.gridDelegate,
    this.itemKeyGenerator,
    this.onItemTap,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// The delegate that controls the grid layout.
  final SliverGridDelegate gridDelegate;

  /// Whether all available items have been fetched.
  final bool hasReachedMax;

  /// Builds the widget for an item in the grid.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Generates a stable key for a grid item.
  final Key Function(T)? itemKeyGenerator;

  /// The items displayed by the grid.
  final List<T> items;

  /// Called when the user approaches the bottom of the grid.
  final VoidCallback onScrollReachedBottom;

  /// Called when an item is tapped.
  final void Function(int)? onItemTap;

  /// Padding around the grid items.
  final EdgeInsetsGeometry padding;

  @override
  State<InfiniteScrollGrid<T>> createState() => _InfiniteScrollGridState<T>();
}

class _InfiniteScrollGridState<T> extends State<InfiniteScrollGrid<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isRequestingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _requestMoreIfViewportIsNotFilled();
  }

  @override
  void didUpdateWidget(covariant InfiniteScrollGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.hasReachedMax != widget.hasReachedMax) {
      _isRequestingMore = false;
      _requestMoreIfViewportIsNotFilled();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SyriusErrorWidget(context.l10n.noItemsFound);
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        SliverPadding(
          padding: widget.padding,
          sliver: SliverGrid.builder(
            gridDelegate: widget.gridDelegate,
            itemCount: widget.items.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildGridItem(
                context,
                widget.items[index],
                index,
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: widget.hasReachedMax
              ? SyriusErrorWidget(context.l10n.noMoreItems)
              : const SyriusLoadingWidget(),
        ),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, T item, int index) {
    final Key? key = widget.itemKeyGenerator?.call(item);
    final Widget child = widget.itemBuilder(context, item, index);

    if (widget.onItemTap == null) {
      return KeyedSubtree(
        key: key,
        child: child,
      );
    }

    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () => widget.onItemTap!(index),
        child: child,
      ),
    );
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.offset;

    return currentScroll >= maxScroll * 0.9;
  }

  void _onScroll() {
    if (_isBottom) {
      _requestMore();
    }
  }

  void _requestMore() {
    if (_isRequestingMore || widget.hasReachedMax) return;

    _isRequestingMore = true;
    try {
      widget.onScrollReachedBottom();
    } on Object {
      _isRequestingMore = false;
      rethrow;
    }
  }

  void _requestMoreIfViewportIsNotFilled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      if (_scrollController.position.maxScrollExtent == 0) {
        _requestMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
