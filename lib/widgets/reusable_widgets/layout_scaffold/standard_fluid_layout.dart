import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:layout/layout.dart';

const int kStaggeredNumOfColumns = 12;

class StandardFluidLayout extends StatelessWidget {
  final List<FluidCell> children;
  final int? defaultCellWidth;
  final double? defaultCellHeight;

  const StandardFluidLayout({
    required this.children,
    this.defaultCellWidth,
    this.defaultCellHeight = kStaggeredNumOfColumns / 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Layout(
      format: FluidLayoutFormat(),
      child: Builder(
        builder: (context) {
          const int crossAxisCount = kStaggeredNumOfColumns;

          final double spacing =
              context.breakpoint < LayoutBreakpoint.sm ? 4.0 : 12.0;

          final List<StaggeredGridTile> tiles = List.generate(
            children.length,
            (index) => _generateStaggeredTitle(children[index]),
          );

          return SingleChildScrollView(
            child: StaggeredGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              children: List.generate(
                tiles.length,
                (index) {
                  final StaggeredGridTile tile = tiles[index];

                  final double totalDurationMs =
                      children.length > 5 ? 800 : 400;

                  final int durationPerTile =
                      totalDurationMs ~/ children.length;

                  return tile;
                },
              ),
            ),
          );
        },
      ),
    );
  }

  StaggeredGridTile _generateStaggeredTitle(FluidCell fluidCell) {
    return StaggeredGridTile.count(
      crossAxisCellCount: fluidCell.width ?? defaultCellWidth!,
      mainAxisCellCount: fluidCell.height ?? defaultCellHeight!,
      child: fluidCell.child,
    );
  }
}

class FluidCell {
  final int? width;
  final double? height;
  final Widget child;

  const FluidCell({
    required this.child,
    this.width,
    this.height,
  });
}
