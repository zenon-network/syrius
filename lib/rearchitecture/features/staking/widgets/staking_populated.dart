import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget associated with the [StakingState] when it's status is
/// [TimerStatus.success] that displays the number of active staking entries
/// and the total staked amount.
class StakingPopulated extends StatelessWidget {
  /// Creates a StakingPopulated object.
  const StakingPopulated({required this.stakingList, super.key});

  /// Field containing the data that will be displayed.
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
        SizedBox.square(
          dimension: 36,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.znnColor,
              ),
            ),
            child: const Icon(
              SimpleLineIcons.energy,
              size: 12,
            ),
          ),
        ),
        kHorizontalGap16,
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: numActiveStakingEntries,
              isInt: true,
              style: context.textTheme.headlineMedium,
            ),
            Text(
              '$totalStakedAmountWithDecimals ${kZnnCoin.symbol}',
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
