// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, non_constant_identifier_names

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: the blockchain should contain that <duration_months> month stake of <amount> ZNN from <stake_address>
Future<void> theBlockchainShouldContainThatMonthStakeOfZnnFrom(
    WidgetTester tester,
    dynamic duration_months,
    dynamic amount,
    dynamic stake_address) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final AccountBlockTemplate expectedBlock = context.stakeBlock!;
  final String stakeAddressText = stake_address as String;
  final BigInt expectedAmount = (amount as String).extractDecimals(
    coinDecimals,
  );
  final int expectedDuration = int.parse(duration_months as String) *
      stakeTimeUnitSec;
  final Address expectedStakeAddress = Address.parse(stakeAddressText);

  final AccountBlock? createdBlock = await _poll<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(expectedBlock.hash),
    isReady: (AccountBlock? block) => block != null,
    description: 'created stake block ${expectedBlock.hash}',
  );

  expect(createdBlock, isNotNull);
  expect(createdBlock!.hash, expectedBlock.hash);
  expect(createdBlock.address, expectedStakeAddress);
  expect(createdBlock.toAddress, stakeAddress);
  expect(createdBlock.tokenStandard, znnZts);
  expect(createdBlock.amount, expectedAmount);

  final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
    Definitions.stake,
    createdBlock.data,
  );
  expect(blockData, isNotNull);
  expect(blockData!.function, 'Stake');
  expect(blockData.params['durationInSec'].toString(), '$expectedDuration');

  final StakeEntry? stakeEntry = await _poll<StakeEntry?>(
    () async {
      final StakeList stakeList = await app.zenon!.embedded.stake
          .getEntriesByAddress(expectedStakeAddress);
      for (final StakeEntry entry in stakeList.list) {
        if (entry.id == expectedBlock.hash) {
          return entry;
        }
      }
      return null;
    },
    isReady: (StakeEntry? entry) => entry != null,
    description: 'stake entry ${expectedBlock.hash}',
  );
  expect(stakeEntry, isNotNull);
  expect(stakeEntry!.id, expectedBlock.hash);
  expect(stakeEntry.address, expectedStakeAddress);
  expect(stakeEntry.amount, expectedAmount);
  expect(
    stakeEntry.expirationTimestamp - stakeEntry.startTimestamp,
    expectedDuration,
  );
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
