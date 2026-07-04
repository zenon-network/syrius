// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: the published pillar QSR deposit block should match <sender>
Future<void> thePublishedPillarQsrDepositBlockShouldMatch(
  WidgetTester tester,
  String sender,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final AccountBlockTemplate expectedBlock = context.pillarQsrDepositBlock!;
  final BigInt expectedAmount = context.pillarQsrDepositAmount!;

  final AccountBlock? createdBlock = await _poll<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(expectedBlock.hash),
    isReady: (AccountBlock? block) => block != null,
    description: 'created pillar QSR deposit block ${expectedBlock.hash}',
  );

  expect(createdBlock, isNotNull);
  expect(createdBlock!.hash, expectedBlock.hash);
  expect(createdBlock.address, Address.parse(sender));
  expect(createdBlock.toAddress, pillarAddress);
  expect(createdBlock.tokenStandard, qsrZts);
  expect(createdBlock.amount, expectedAmount);
  expect(createdBlock.data, orderedEquals(expectedBlock.data));

  final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
    Definitions.common,
    createdBlock.data,
  );
  expect(blockData, isNotNull);
  expect(blockData!.function, 'DepositQsr');
}

Future<T> _poll<T>(
  Future<T> Function() fetch, {
  required bool Function(T value) isReady,
  required String description,
}) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 90));
  Object? lastError;

  while (DateTime.now().isBefore(deadline)) {
    try {
      final T value = await fetch();
      if (isReady(value)) {
        return value;
      }
    } on Object catch (error) {
      lastError = error;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  throw TimeoutException(
    'Timed out waiting for $description. Last error: $lastError',
  );
}
