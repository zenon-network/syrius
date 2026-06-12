import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays the Pillars tab content in a responsive fluid layout.
class PillarsTabChild extends StatelessWidget {
  /// Creates a Pillars tab child.
  const PillarsTabChild({
    required VoidCallback onStepperNotificationSeeMorePressed,
    super.key,
  }) : _onStepperNotificationSeeMorePressed =
           onStepperNotificationSeeMorePressed;

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    final List<FluidCell> children = <FluidCell>[
      FluidCell(
        child: const PillarRewardsCard(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: const PillarCollectCard(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: PillarStatsCard(
          onStepperNotificationSeeMorePressed:
              _onStepperNotificationSeeMorePressed,
        ),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      const FluidCell(
        child: PillarsCard(),
        width: kStaggeredNumOfColumns,
        height: kStaggeredNumOfColumns / 2,
      ),
    ];
    return BlocProvider<PillarsBloc>(
      create: (_) =>
          PillarsBloc(zenon: zenon!)
            ..add(const InfiniteListRequested(address: null)),
      child: StandardFluidLayout(
        children: children,
      ),
    );
  }
}
