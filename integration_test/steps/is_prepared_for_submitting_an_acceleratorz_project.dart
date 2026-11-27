// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/accelerator_devnet_helpers.dart';
import '../support/devnet_bdd_helpers.dart';
import '../support/devnet_test_context.dart';

/// Usage: <owner_address> is prepared for submitting an Accelerator-Z project
Future<void> isPreparedForSubmittingAnAcceleratorzProject(
  WidgetTester tester,
  String ownerAddress,
) async {
  AcceleratorDevnetContext.create().ownerAddress = ownerAddress;
  selectDevnetSender(ownerAddress);

  final Address parsedOwner = Address.parse(ownerAddress);
  final AccountInfo ownerInfo = await app.zenon!.ledger.getAccountInfoByAddress(
    parsedOwner,
  );
  expect(
    ownerInfo.getBalance(znnZts),
    greaterThanOrEqualTo(projectCreationFeeInZnn),
    reason:
        'Accelerator project owner $ownerAddress does not have enough ZNN '
        'for the project creation fee',
  );

  final PillarInfoList pillars = await app.zenon!.embedded.pillar.getAll(
    pageSize: 10,
  );
  expect(
    pillars.list,
    isNotEmpty,
    reason: 'Devnet must have active Pillars for Accelerator-Z voting',
  );

  await ensureDevnetPlasma(ownerAddress);
  selectDevnetSender(ownerAddress);
}
