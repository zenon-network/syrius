import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DelegationPopulated extends StatelessWidget {

  const DelegationPopulated({required this.data, super.key});
  final DelegationInfo data;

  @override
  Widget build(BuildContext context) {
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
              color: data.status == 1
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
              data.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${data.weight.addDecimals(coinDecimals)} ${kZnnCoin.symbol}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
