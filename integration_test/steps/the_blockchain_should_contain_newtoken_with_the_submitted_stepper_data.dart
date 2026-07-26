// BDD Usage comments intentionally mirror Gherkin step text.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: the blockchain should contain NewToken with the submitted stepper data
Future<void> theBlockchainShouldContainNewtokenWithTheSubmittedStepperData(
  WidgetTester tester,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final AccountBlockTemplate expectedBlock = context.issueTokenBlock!;
  final Address ownerAddress = Address.parse(
    DevnetTestContext.testTokenOwnerAddress,
  );
  final BigInt scale = BigInt.from(10).pow(
    DevnetTestContext.testTokenDecimals,
  );
  final BigInt expectedMaxSupply =
      BigInt.parse(DevnetTestContext.testTokenMaxSupply) * scale;
  final BigInt expectedTotalSupply =
      BigInt.parse(DevnetTestContext.testTokenTotalSupply) * scale;

  final AccountBlock? createdBlock = await _poll<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(expectedBlock.hash),
    isReady: (AccountBlock? block) =>
        block?.confirmationDetail != null &&
        block!.confirmationDetail!.numConfirmations >= 1,
    description: 'confirmed token issue block ${expectedBlock.hash}',
  );

  expect(createdBlock, isNotNull);
  expect(createdBlock!.hash, expectedBlock.hash);
  expect(createdBlock.chainIdentifier, DevnetTestContext.chainId);
  expect(createdBlock.blockType, BlockTypeEnum.userSend.index);
  expect(createdBlock.address, ownerAddress);
  expect(createdBlock.toAddress, tokenAddress);
  expect(createdBlock.tokenStandard, znnZts);
  expect(createdBlock.amount, tokenZtsIssueFeeInZnn);
  expect(
    createdBlock.confirmationDetail!.numConfirmations,
    greaterThanOrEqualTo(1),
  );

  final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
    Definitions.token,
    createdBlock.data,
  );
  expect(blockData, isNotNull);
  expect(blockData!.function, 'IssueToken');
  expect(
    blockData.params['tokenName'],
    DevnetTestContext.testTokenName,
  );
  expect(
    blockData.params['tokenSymbol'],
    DevnetTestContext.testTokenSymbol,
  );
  expect(
    blockData.params['tokenDomain'],
    DevnetTestContext.testTokenDomain,
  );
  expect(
    BigInt.parse(blockData.params['totalSupply'].toString()),
    expectedTotalSupply,
  );
  expect(
    BigInt.parse(blockData.params['maxSupply'].toString()),
    expectedMaxSupply,
  );
  expect(
    BigInt.parse(blockData.params['decimals'].toString()),
    BigInt.from(DevnetTestContext.testTokenDecimals),
  );
  expect(blockData.params['isMintable'], isTrue);
  expect(blockData.params['isBurnable'], isTrue);
  expect(blockData.params['isUtility'], isTrue);

  final TokenStandard expectedZts = TokenStandard.fromBytes(
    Crypto.digest(createdBlock.hash.getBytes()!).sublist(
      0,
      TokenStandard.coreSize,
    ),
  );
  final Token? token = await _poll<Token?>(
    () => app.zenon!.embedded.token.getByZts(expectedZts),
    isReady: (Token? value) => value != null,
    description: 'issued token $expectedZts',
  );

  expect(token, isNotNull);
  expect(token!.tokenStandard, expectedZts);
  expect(token.owner, ownerAddress);
  expect(token.name, DevnetTestContext.testTokenName);
  expect(token.symbol, DevnetTestContext.testTokenSymbol);
  expect(token.domain, DevnetTestContext.testTokenDomain);
  expect(token.totalSupply, expectedTotalSupply);
  expect(token.maxSupply, expectedMaxSupply);
  expect(token.decimals, DevnetTestContext.testTokenDecimals);
  expect(token.isMintable, isTrue);
  expect(token.isBurnable, isTrue);
  expect(token.isUtility, isTrue);
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
