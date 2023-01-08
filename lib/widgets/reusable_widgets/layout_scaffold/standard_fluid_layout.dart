import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const int kStaggeredNumOfColumns = 12;

class StandardFluidLayout extends StatelessWidget {
  final List<FluidCell> children;
  final int? defaultCellWidth;
  final double? defaultCellHeight;

  const StandardFluidLayout({
    required this.children,
    this.defaultCellWidth,
    this.defaultCellHeight = kStaggeredNumOfColumns / 4,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: RemoveOverscrollEffect(),
      child: Layout(
        format: FluidLayoutFormat(),
        child: Builder(
          builder: (context) {
            const int crossAxisCount = kStaggeredNumOfColumns;
            return CustomScrollView(
              slivers: [
                SliverStaggeredGrid(
                  delegate: SliverChildListDelegate.fixed(
                    List.generate(
                      children.length,
                      (index) => WidgetAnimator(
                        curve: Curves.linear,
                        animationOffset: Duration(
                          milliseconds: ((children.length > 5 ? 800 : 400) ~/
                                  children.length) *
                              (index + 1),
                        ),
                        child: children[index].child,
                      ),
                    ),
                  ),
                  gridDelegate:
                      SliverStaggeredGridDelegateWithFixedCrossAxisCount(
                    mainAxisSpacing:
                        context.breakpoint < LayoutBreakpoint.sm ? 4 : 12.0,
                    crossAxisSpacing:
                        context.breakpoint < LayoutBreakpoint.sm ? 4 : 12.0,
                    crossAxisCount: crossAxisCount,
                    staggeredTileCount: children.length,
                    staggeredTileBuilder: (index) => StaggeredTile.count(
                      children[index].width ?? defaultCellWidth!,
                      children[index].height ?? defaultCellHeight!,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
