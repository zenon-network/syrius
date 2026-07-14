// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: <stake_address> address has funds for staking <amount> ZNN
Future<void> addressHasFundsForStakingZnn(
  WidgetTester tester,
  dynamic stake_address,
  dynamic amount,
) async {
  final String stakeAddress = stake_address as String;
  final BigInt stakeAmount = (amount as String).extractDecimals(coinDecimals);

  selectDevnetSender(stakeAddress);
  final Address address = Address.parse(stakeAddress);
  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(address);
  final PlasmaInfo plasmaInfo = await app.zenon!.embedded.plasma.get(address);

  expect(
    accountInfo.getBalance(znnZts),
    greaterThanOrEqualTo(stakeAmount),
    reason: 'Stake address does not have enough ZNN for the test stake',
  );
  expect(
    plasmaInfo.currentPlasma,
    greaterThanOrEqualTo(kStakePlasmaAmountNeeded),
    reason: 'Stake address does not have enough plasma to create a stake',
  );
}
