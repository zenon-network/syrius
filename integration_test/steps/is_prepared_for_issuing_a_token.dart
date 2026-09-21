// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: <token_owner> is prepared for issuing a token
Future<void> isPreparedForIssuingAToken(
  WidgetTester tester,
  dynamic token_owner,
) async {
  final String owner = token_owner as String;
  selectDevnetSender(owner);

  final Address ownerAddress = Address.parse(owner);
  final PlasmaInfo plasmaInfo = await app.zenon!.embedded.plasma.get(
    ownerAddress,
  );
  expect(
    plasmaInfo.currentPlasma,
    greaterThanOrEqualTo(kIssueTokenPlasmaAmountNeeded),
    reason: 'Token owner does not have enough plasma to issue a token',
  );

  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(ownerAddress);
  expect(
    accountInfo.getBalance(znnZts),
    greaterThanOrEqualTo(tokenZtsIssueFeeInZnn),
    reason: 'Token owner does not have enough ZNN for the issuance fee',
  );
}
