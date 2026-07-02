// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: <sender> address has funds
Future<void> addressHasFunds(WidgetTester tester, String sender) async {
  selectDevnetSender(sender);
  final Address derivedSenderAddress = Address.parse(sender);

  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(
        derivedSenderAddress,
      );
  expect(accountInfo.getBalance(znnZts), greaterThan(BigInt.zero));
}
