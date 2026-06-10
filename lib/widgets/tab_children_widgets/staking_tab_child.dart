import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Tab content for staking-related cards and lists.
class StakingTabChild extends StatefulWidget {
  /// Creates a staking tab child.
  const StakingTabChild({super.key});

  @override
  State<StakingTabChild> createState() {
    return _StakingTabChildState();
  }
}

class _StakingTabChildState extends State<StakingTabChild> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<StakesBloc>(
      create: (_) => StakesBloc(zenon: zenon!)
        ..add(
          InfiniteListRequested(address: Address.parse(kSelectedAddress!)),
        ),
      child: Builder(
        builder: _buildFluidLayout,
      ),
    );
  }

  Widget _buildFluidLayout(BuildContext context) {
    final List<FluidCell> children = <FluidCell>[
      FluidCell(
        child: const StakingRewardsCard(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: const StakeCollectCard(),
        width: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 3,
          lg: kStaggeredNumOfColumns ~/ 3,
          md: kStaggeredNumOfColumns ~/ 3,
          sm: kStaggeredNumOfColumns ~/ 2,
          xs: kStaggeredNumOfColumns,
        ),
      ),
      FluidCell(
        child: StakingOptionsCard(
          onStakeCreated: () {
            context.read<StakesBloc>().add(
              InfiniteListRefreshRequested(
                address: Address.parse(kSelectedAddress!),
              ),
            );
          },
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
        child: StakesCard(),
        width: kStaggeredNumOfColumns,
        height: kStaggeredNumOfColumns / 2,
      ),
    ];

    return StandardFluidLayout(
      children: children,
    );
  }
}
