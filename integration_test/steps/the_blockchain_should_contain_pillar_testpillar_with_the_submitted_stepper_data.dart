// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: the blockchain should contain pillar testPillar with the submitted stepper data
Future<void>
theBlockchainShouldContainPillarTestpillarWithTheSubmittedStepperData(
  WidgetTester tester,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final AccountBlockTemplate expectedBlock = context.deployPillarBlock!;
  const String name = DevnetTestContext.testPillarName;
  const String owner = DevnetTestContext.testPillarOwnerAddress;
  const String rewardAddress = DevnetTestContext.testPillarRewardAddress;
  const String producerAddress = DevnetTestContext.testPillarProducerAddress;
  const int momentumReward = DevnetTestContext.testPillarMomentumReward;
  const int delegationReward = DevnetTestContext.testPillarDelegationReward;

  final AccountBlock? createdBlock = await _poll<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(expectedBlock.hash),
    isReady: (AccountBlock? block) => block != null,
    description: 'created pillar registration block ${expectedBlock.hash}',
  );

  expect(createdBlock, isNotNull);
  expect(createdBlock!.hash, expectedBlock.hash);
  expect(createdBlock.address, Address.parse(owner));
  expect(createdBlock.toAddress, pillarAddress);
  expect(createdBlock.tokenStandard, znnZts);
  expect(createdBlock.amount, pillarRegisterZnnAmount);

  final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
    Definitions.pillar,
    createdBlock.data,
  );
  expect(blockData, isNotNull);
  expect(blockData!.function, 'Register');
  expect(blockData.params['name'], name);
  expect(blockData.params['producerAddress'].toString(), producerAddress);
  expect(blockData.params['rewardAddress'].toString(), rewardAddress);
  expect(
    int.parse(blockData.params['giveBlockRewardPercentage'].toString()),
    momentumReward,
  );
  expect(
    int.parse(blockData.params['giveDelegateRewardPercentage'].toString()),
    delegationReward,
  );

  final PillarInfo? pillarInfo = await _poll<PillarInfo?>(
    () => app.zenon!.embedded.pillar.getByName(name),
    isReady: (PillarInfo? pillarInfo) => pillarInfo != null,
    description: 'pillar $name to be available by name',
  );

  expect(pillarInfo, isNotNull);
  expect(pillarInfo!.name, name);
  expect(pillarInfo.ownerAddress, Address.parse(owner));
  expect(pillarInfo.withdrawAddress, Address.parse(rewardAddress));
  expect(pillarInfo.producerAddress, Address.parse(producerAddress));
  expect(pillarInfo.giveMomentumRewardPercentage, momentumReward);
  expect(pillarInfo.giveDelegateRewardPercentage, delegationReward);
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
