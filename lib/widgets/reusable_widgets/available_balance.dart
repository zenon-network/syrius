import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AvailableBalance extends StatelessWidget {

  const AvailableBalance(
    this.token,
    this.accountInfo, {
    super.key,
  });
  final Token token;
  final AccountInfo accountInfo;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${accountInfo.getBalance(
            token.tokenStandard,
          ).addDecimals(token.decimals)} '
      '${token.symbol} available',
      style: Theme.of(context).inputDecorationTheme.hintStyle,
    );
  }
}
