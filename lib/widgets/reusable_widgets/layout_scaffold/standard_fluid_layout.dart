import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/widget_animator.dart';

const int kStaggeredNumOfColumns = 12;

class StandardFluidLayout extends StatelessWidget {

  const StandardFluidLayout({
    required this.children,
    this.defaultCellWidth,
    this.defaultCellHeight = kStaggeredNumOfColumns / 4,
    super.key,
  });
  final List<FluidCell> children;
  final int? defaultCellWidth;
  final double? defaultCellHeight;

  final List<FluidCell> children;
  final int? defaultCellWidth;
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

class FluidCell {

  const FluidCell({
    required this.child,
    this.width,
    this.height,
  });

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

  final int? width;
  final double? height;
  final Widget child;
}
