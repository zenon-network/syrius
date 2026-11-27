// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/accelerator_devnet_helpers.dart';

/// Usage: the blockchain should contain the submitted Accelerator-Z project with <name>, <description>, <url>, <znn_funds>, and <qsr_funds>
Future<void> theBlockchainShouldContainTheSubmittedAcceleratorzProjectWithAnd(
  WidgetTester tester,
  String name,
  String description,
  String url,
  String znnFunds,
  String qsrFunds,
) async {
  final AcceleratorDevnetContext acceleratorContext =
      requireAcceleratorDevnetContext();
  final AccountBlockTemplate expectedBlock =
      acceleratorContext.createProjectBlock!;
  final Hash projectId = acceleratorContext.projectId!;
  final BigInt expectedZnn = znnFunds.extractDecimals(coinDecimals);
  final BigInt expectedQsr = qsrFunds.extractDecimals(coinDecimals);

  final AccountBlock? confirmedBlock = await pollAccelerator<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(expectedBlock.hash),
    isReady: (AccountBlock? block) =>
        block?.confirmationDetail?.momentumTimestamp != null,
    description: 'confirmed CreateProject block ${expectedBlock.hash}',
  );

  expect(confirmedBlock, isNotNull);
  expect(confirmedBlock!.hash, expectedBlock.hash);
  expect(confirmedBlock.toAddress, acceleratorAddress);
  expect(confirmedBlock.tokenStandard, znnZts);
  expect(confirmedBlock.amount, projectCreationFeeInZnn);

  final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
    Definitions.accelerator,
    confirmedBlock.data,
  );
  expect(blockData, isNotNull);
  expect(blockData!.function, 'CreateProject');
  expect(blockData.params['name'], name);
  expect(blockData.params['description'], description);
  expect(blockData.params['url'], url);
  expect(
    BigInt.parse(blockData.params['znnFundsNeeded'].toString()),
    expectedZnn,
  );
  expect(
    BigInt.parse(blockData.params['qsrFundsNeeded'].toString()),
    expectedQsr,
  );

  final Project onChainProject = await pollAccelerator<Project>(
    () => app.zenon!.embedded.accelerator.getProjectById(projectId.toString()),
    isReady: (Project project) => project.id == projectId,
    description: 'Accelerator-Z project $projectId on-chain',
  );

  expect(onChainProject.id, projectId);
  expect(onChainProject.owner, confirmedBlock.address);
  expect(onChainProject.name, name);
  expect(onChainProject.description, description);
  expect(onChainProject.url, url);
  expect(onChainProject.znnFundsNeeded, expectedZnn);
  expect(onChainProject.qsrFundsNeeded, expectedQsr);
  expect(onChainProject.status, AcceleratorProjectStatus.voting);

  final ProjectList allProjects = await app.zenon!.embedded.accelerator.getAll(
    pageSize: 50,
  );
  expect(
    allProjects.list.any((Project project) => project.id == projectId),
    isTrue,
    reason: 'Expected accelerator.getAll to include project $projectId',
  );

  acceleratorContext.submittedProject = onChainProject;
}
