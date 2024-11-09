import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
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
        SizedBox.square(
          dimension: 36,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: delegationInfo.status == 1
                    ? AppColors.znnColor
                    : AppColors.errorColor,
              ),
            ),
            child: const Icon(
              SimpleLineIcons.trophy,
              size: 12,
            ),
          ),
        ),
        kHorizontalGap16,
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pillarName,
              style: context.textTheme.bodyMedium,
            ),
            Text(
              '${weight.addDecimals(coinDecimals)} ${kZnnCoin.symbol}',
              style: context.textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
