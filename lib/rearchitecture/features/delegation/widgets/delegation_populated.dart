import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the delegation amount and to which pillar the amount
/// was delegated to.
class DelegationPopulated extends StatelessWidget {
  /// Creates a DelegationPopulated object.
  const DelegationPopulated({required this.delegationInfo, super.key});

  /// Field that holds the needed details
  final DelegationInfo delegationInfo;

  @override
  Widget build(BuildContext context) {
    final String pillarName = delegationInfo.name;
    final BigInt weight = delegationInfo.weight;

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
              color: delegationInfo.status == 1
                  ? AppColors.znnColor
                  : AppColors.errorColor,
            ),
          ),
          child: Icon(
            SimpleLineIcons.trophy,
            size: 12,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        Container(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pillarName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${weight.addDecimals(coinDecimals)} ${kZnnCoin.symbol}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
