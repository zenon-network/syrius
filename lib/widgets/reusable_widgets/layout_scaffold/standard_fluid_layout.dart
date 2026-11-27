import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/widget_animator.dart';

/// Default number of columns in a [StandardFluidLayout] staggered grid.
const int kStaggeredNumOfColumns = 12;

/// Responsive staggered grid layout animating [FluidCell] children into view.
class StandardFluidLayout extends StatelessWidget {
  /// Creates a [StandardFluidLayout].
  const StandardFluidLayout({
    required this.children,
    this.defaultCellWidth,
    this.defaultCellHeight = kStaggeredNumOfColumns / 4,
    super.key,
  });

  /// Grid cells arranged in the staggered layout.
  final List<FluidCell> children;

  /// Default column span used when a cell omits [FluidCell.width].
  final int? defaultCellWidth;

  /// Default row span used when a cell omits [FluidCell.height].
  final double? defaultCellHeight;

  @override
  Widget build(BuildContext context) {
    return Layout(
      format: FluidLayoutFormat(),
      child: Builder(
        builder: (BuildContext context) {
          const int crossAxisCount = kStaggeredNumOfColumns;

          final double spacing =
              context.breakpoint < LayoutBreakpoint.sm ? 4.0 : 12.0;

          final int totalDurationMs = children.length > 5 ? 800 : 400;

          final int durationPerTile = totalDurationMs ~/ children.length;

          final List<StaggeredGridTile> tiles =
              List<StaggeredGridTile>.generate(
            children.length,
            (int index) {
              final int widgetAnimatorOffset = durationPerTile * (index + 1);

              return _generateStaggeredTitle(
                children[index],
                widgetAnimatorOffset,
              );
            },
          );

          return SingleChildScrollView(
            child: StaggeredGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              children: tiles,
            ),
          );
        },
      ),
    );
  }

  StaggeredGridTile _generateStaggeredTitle(
    FluidCell fluidCell,
    int widgetAnimatorOffset,
  ) {
    return StaggeredGridTile.count(
      crossAxisCellCount: fluidCell.width ?? defaultCellWidth!,
      mainAxisCellCount: fluidCell.height ?? defaultCellHeight!,
      child: WidgetAnimator(
        animationOffset: Duration(
          milliseconds: widgetAnimatorOffset,
        ),
        child: fluidCell.child,
      ),
    );
  }
}

/// Cell descriptor specifying dimensions and content for [StandardFluidLayout].
class FluidCell {
  /// Creates a [FluidCell] with explicit optional [width] and [height].
  const FluidCell({
    required this.child,
    this.width,
    this.height,
  });

  /// Creates a wide responsive [FluidCell].
  FluidCell.large({
    required Widget child,
    required BuildContext context,
  }) : this(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 1.2,
            lg: kStaggeredNumOfColumns ~/ 1.2,
            md: kStaggeredNumOfColumns ~/ 1.2,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: child,
        );

  /// Creates a half-width responsive [FluidCell] on desktop breakpoints.
  FluidCell.medium({required Widget child, required BuildContext context})
      : this(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 2,
            lg: kStaggeredNumOfColumns ~/ 2,
            md: kStaggeredNumOfColumns ~/ 2,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: child,
        );

  /// Creates a compact responsive [FluidCell].
  FluidCell.small({required Widget child, required BuildContext context})
      : this(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 6,
            lg: kStaggeredNumOfColumns ~/ 6,
            md: kStaggeredNumOfColumns ~/ 6,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: child,
        );

  /// Column span of the cell within the staggered grid.
  final int? width;

  /// Row span of the cell within the staggered grid.
  final double? height;

  /// Widget rendered inside the cell.
  final Widget child;
}
