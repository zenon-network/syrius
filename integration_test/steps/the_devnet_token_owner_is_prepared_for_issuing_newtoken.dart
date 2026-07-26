import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: the devnet token owner is prepared for issuing NewToken
Future<void> theDevnetTokenOwnerIsPreparedForIssuingNewtoken(
  WidgetTester tester,
) async {
  const String owner = DevnetTestContext.testTokenOwnerAddress;
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
