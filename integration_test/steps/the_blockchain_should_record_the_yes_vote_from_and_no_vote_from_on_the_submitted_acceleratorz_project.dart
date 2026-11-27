// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/accelerator_devnet_helpers.dart';
import '../support/devnet_bdd_helpers.dart';

/// Usage: the blockchain should record the yes vote from <producer_pillar> and no vote from <owner_pillar> on the submitted Accelerator-Z project
Future<void>
theBlockchainShouldRecordTheYesVoteFromAndNoVoteFromOnTheSubmittedAcceleratorzProject(
  WidgetTester tester,
  String producerPillar,
  String ownerPillar,
) async {
  final AcceleratorDevnetContext acceleratorContext =
      requireAcceleratorDevnetContext();
  final Hash projectId = acceleratorContext.projectId!;
  final AccountBlockTemplate producerVoteBlock =
      acceleratorContext.producerVoteBlock!;
  final AccountBlockTemplate ownerVoteBlock =
      acceleratorContext.ownerVoteBlock!;

  final AccountBlock? confirmedProducerVote = await pollDevnet<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(producerVoteBlock.hash),
    isReady: (AccountBlock? block) =>
        block?.confirmationDetail?.momentumTimestamp != null,
    description: 'confirmed VoteByProdAddress block ${producerVoteBlock.hash}',
  );
  expect(confirmedProducerVote, isNotNull);
  expect(confirmedProducerVote!.toAddress, acceleratorAddress);

  final BlockData? producerVoteData = AccountBlockUtils.getDecodedBlockData(
    Definitions.accelerator,
    confirmedProducerVote.data,
  );
  expect(producerVoteData, isNotNull);
  expect(producerVoteData!.function, 'VoteByProdAddress');
  expect(producerVoteData.params['id'], projectId);
  expect(
    int.parse(producerVoteData.params['vote'].toString()),
    AcceleratorProjectVote.yes.index,
  );

  final AccountBlock? confirmedOwnerVote = await pollDevnet<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(ownerVoteBlock.hash),
    isReady: (AccountBlock? block) =>
        block?.confirmationDetail?.momentumTimestamp != null,
    description: 'confirmed VoteByName block ${ownerVoteBlock.hash}',
  );
  expect(confirmedOwnerVote, isNotNull);
  expect(confirmedOwnerVote!.toAddress, acceleratorAddress);

  final BlockData? ownerVoteData = AccountBlockUtils.getDecodedBlockData(
    Definitions.accelerator,
    confirmedOwnerVote.data,
  );
  expect(ownerVoteData, isNotNull);
  expect(ownerVoteData!.function, 'VoteByName');
  expect(ownerVoteData.params['id'], projectId);
  expect(ownerVoteData.params['name'], ownerPillar);
  expect(
    int.parse(ownerVoteData.params['vote'].toString()),
    AcceleratorProjectVote.no.index,
  );

  final VoteBreakdown voteBreakdown = await pollDevnet<VoteBreakdown>(
    () => app.zenon!.embedded.accelerator.getVoteBreakdown(projectId),
    isReady: (VoteBreakdown breakdown) =>
        breakdown.yes == 1 && breakdown.no == 1 && breakdown.total == 2,
    description: 'vote breakdown for project $projectId to reflect both votes',
  );
  expect(voteBreakdown.id, projectId);
  expect(voteBreakdown.yes, 1);
  expect(voteBreakdown.no, 1);
  expect(voteBreakdown.total, 2);

  final List<PillarVote?> producerVotes = await app.zenon!.embedded.accelerator
      .getPillarVotes(producerPillar, <String>[projectId.toString()]);
  expect(producerVotes, hasLength(1));
  expect(producerVotes.first, isNotNull);
  expect(producerVotes.first!.name, producerPillar);
  expect(producerVotes.first!.vote, AcceleratorProjectVote.yes.index);

  final List<PillarVote?> ownerVotes = await app.zenon!.embedded.accelerator
      .getPillarVotes(ownerPillar, <String>[projectId.toString()]);
  expect(ownerVotes, hasLength(1));
  expect(ownerVotes.first, isNotNull);
  expect(ownerVotes.first!.name, ownerPillar);
  expect(ownerVotes.first!.vote, AcceleratorProjectVote.no.index);
}
