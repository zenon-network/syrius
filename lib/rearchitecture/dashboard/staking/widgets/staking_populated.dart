import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget associated with the [StakingState] when it's status is
/// [CubitStatus.success] that displays
class StakingPopulated extends StatelessWidget {
  /// Creates a StakingPopulated object
  const StakingPopulated({required this.stakingList, super.key});

  final StakeList stakingList;

  @override
  Widget build(BuildContext context) {
    final int numActiveStakingEntries = stakingList.list.length;
    final BigInt totalStakedAmount = stakingList.totalAmount;
    final String totalStakedAmountWithDecimals = totalStakedAmount.addDecimals(
      coinDecimals,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.znnColor,
            ),
          ),
          child: Icon(
            SimpleLineIcons.energy,
            size: 12,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        Container(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: numActiveStakingEntries,
              isInt: true,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '$totalStakedAmountWithDecimals ${kZnnCoin.symbol}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
