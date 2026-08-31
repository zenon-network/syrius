// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars, non_constant_identifier_names

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: the returned issue block from <token_owner> should contain <token_name>, <token_symbol>, <website>, <mintable>, <burnable>, <decimals>, <max_supply>, <total_supply>, and <utility>
Future<void> theReturnedIssueBlockFromShouldContainAnd(
  WidgetTester tester,
  dynamic token_owner,
  dynamic token_name,
  dynamic token_symbol,
  dynamic website,
  dynamic mintable,
  dynamic burnable,
  dynamic decimals,
  dynamic max_supply,
  dynamic total_supply,
  dynamic utility,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final AccountBlockTemplate expectedBlock = context.issueTokenBlock!;
  final Address ownerAddress = Address.parse(token_owner as String);
  final String tokenName = token_name as String;
  final String tokenSymbol = token_symbol as String;
  final String tokenWebsite = website as String;
  final bool isMintable = bool.parse(mintable as String);
  final bool isBurnable = bool.parse(burnable as String);
  final int tokenDecimals = int.parse(decimals as String);
  final bool isUtility = bool.parse(utility as String);
  final BigInt scale = BigInt.from(10).pow(tokenDecimals);
  final BigInt expectedMaxSupply =
      BigInt.parse(max_supply as String) * scale;
  final BigInt expectedTotalSupply =
      BigInt.parse(total_supply as String) * scale;

  final AccountBlock? createdBlock = await _poll<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(expectedBlock.hash),
    isReady: (AccountBlock? block) =>
        block?.confirmationDetail != null &&
        block!.confirmationDetail!.numConfirmations >= 1,
    description: 'confirmed token issue block ${expectedBlock.hash}',
  );

  expect(createdBlock, isNotNull);
  expect(createdBlock!.hash, expectedBlock.hash);
  expect(createdBlock.chainIdentifier, expectedBlock.chainIdentifier);
  expect(createdBlock.blockType, BlockTypeEnum.userSend.index);
  expect(createdBlock.address, ownerAddress);
  expect(createdBlock.toAddress, tokenAddress);
  expect(createdBlock.data, expectedBlock.data);
  expect(
    createdBlock.confirmationDetail!.numConfirmations,
    greaterThanOrEqualTo(1),
  );

  final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
    Definitions.token,
    expectedBlock.data,
  );
  expect(blockData, isNotNull);
  expect(blockData!.function, 'IssueToken');
  expect(blockData.params['tokenName'], tokenName);
  expect(blockData.params['tokenSymbol'], tokenSymbol);
  expect(blockData.params['tokenDomain'], tokenWebsite);
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
    BigInt.from(tokenDecimals),
  );
  expect(blockData.params['isMintable'], isMintable);
  expect(blockData.params['isBurnable'], isBurnable);
  expect(blockData.params['isUtility'], isUtility);

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
  expect(token.name, tokenName);
  expect(token.symbol, tokenSymbol);
  expect(token.domain, tokenWebsite);
  expect(token.totalSupply, expectedTotalSupply);
  expect(token.maxSupply, expectedMaxSupply);
  expect(token.decimals, tokenDecimals);
  expect(token.isMintable, isMintable);
  expect(token.isBurnable, isBurnable);
  expect(token.isUtility, isUtility);
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
