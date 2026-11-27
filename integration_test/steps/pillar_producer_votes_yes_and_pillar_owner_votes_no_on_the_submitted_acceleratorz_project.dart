// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/accelerator_devnet_helpers.dart';
import '../support/devnet_test_context.dart';

/// Usage: Pillar producer <producer_address> votes yes and Pillar owner <pillar_owner_address> votes no on the submitted Accelerator-Z project
Future<void>
pillarProducerVotesYesAndPillarOwnerVotesNoOnTheSubmittedAcceleratorzProject(
  WidgetTester tester,
  String producerAddress,
  String pillarOwnerAddress,
) async {
  final AcceleratorDevnetContext acceleratorContext =
      requireAcceleratorDevnetContext();
  final Hash projectId = acceleratorContext.projectId!;

  final AccountBlockTemplate producerVoteBlock =
      await _castVoteThroughAcceleratorUi(
        tester: tester,
        projectId: projectId,
        voterAddress: producerAddress,
        voteButtonKey: const Key('accelerator_vote_yes_button'),
        expectedProducerRole: true,
      );

  final AccountBlockTemplate ownerVoteBlock =
      await _castVoteThroughAcceleratorUi(
        tester: tester,
        projectId: projectId,
        voterAddress: pillarOwnerAddress,
        voteButtonKey: const Key('accelerator_vote_no_button'),
        expectedProducerRole: false,
      );

  acceleratorContext
    ..producerVoteBlock = producerVoteBlock
    ..ownerVoteBlock = ownerVoteBlock;
}

Future<AccountBlockTemplate> _castVoteThroughAcceleratorUi({
  required WidgetTester tester,
  required Hash projectId,
  required String voterAddress,
  required Key voteButtonKey,
  required bool expectedProducerRole,
}) async {
  await ensureAcceleratorPlasma(voterAddress);
  selectDevnetSender(voterAddress);

  final Address parsedVoter = Address.parse(voterAddress);
  final AcceleratorPillarBloc pillarBloc = AcceleratorPillarBloc(
    zenon: app.zenon!,
  );
  final ProjectListBloc projectListBloc = ProjectListBloc(zenon: app.zenon!);
  StreamSubscription<VoteProjectState>? voteSubscription;

  try {
    final Future<AcceleratorPillarPopulated> pillarFuture = pillarBloc.stream
        .firstWhere(
          (AcceleratorPillarState state) =>
              state is AcceleratorPillarPopulated ||
              state is AcceleratorPillarFailure,
        )
        .then((AcceleratorPillarState state) {
          if (state is AcceleratorPillarFailure) {
            throw state.exception;
          }
          return state as AcceleratorPillarPopulated;
        });
    pillarBloc.add(AcceleratorPillarRequested(address: parsedVoter));

    final AcceleratorPillarPopulated resolvedPillar =
        await pumpUntilAcceleratorComplete<AcceleratorPillarPopulated>(
          tester,
          pillarFuture,
          'AcceleratorPillarBloc resolution for $voterAddress',
        );
    final PillarInfo? pillarInfo = resolvedPillar.pillarInfo;
    expect(
      pillarInfo,
      isNotNull,
      reason: 'Expected $voterAddress to resolve to a devnet Pillar',
    );
    if (expectedProducerRole) {
      expect(pillarInfo!.producerAddress, parsedVoter);
      expect(pillarInfo.ownerAddress, isNot(parsedVoter));
    } else {
      expect(pillarInfo!.ownerAddress, parsedVoter);
    }

    projectListBloc.add(
      ProjectListPillarUpdated(pillarInfo: pillarInfo, refresh: true),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<ProjectListBloc>.value(
            value: projectListBloc,
            child: AcceleratorProjectsCard(
              pillarInfo: pillarInfo,
              activePillarCount: resolvedPillar.activePillarCount,
              onStepperNotificationSeeMorePressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder projectItemFinder = find.byKey(
      ValueKey<String>(projectId.toString()),
    );
    await pumpUntilAcceleratorFound(
      tester,
      projectItemFinder,
      description: 'AcceleratorProjectListItem for $projectId',
    );

    final Finder voteButtonFinder = find.descendant(
      of: projectItemFinder,
      matching: find.byKey(voteButtonKey),
    );
    await pumpUntilAcceleratorFound(
      tester,
      voteButtonFinder,
      description: 'Vote button $voteButtonKey for project $projectId',
    );
    await tester.ensureVisible(voteButtonFinder);
    await tester.pump(const Duration(milliseconds: 100));

    final VoteProjectBloc voteBloc = tester
        .element(voteButtonFinder)
        .read<VoteProjectBloc>();
    final Completer<AccountBlockTemplate> voteCompleter =
        Completer<AccountBlockTemplate>();
    voteSubscription = voteBloc.stream.listen((VoteProjectState state) {
      if (state is VoteProjectDone && !voteCompleter.isCompleted) {
        voteCompleter.complete(state.accountBlock);
      } else if (state is VoteProjectFailure && !voteCompleter.isCompleted) {
        voteCompleter.completeError(state.exception);
      }
    });

    await tester.tap(voteButtonFinder);
    return await pumpUntilAcceleratorComplete<AccountBlockTemplate>(
      tester,
      voteCompleter.future,
      'VoteProjectBloc confirmation for $voterAddress',
    );
  } finally {
    await voteSubscription?.cancel();
    await tester.pumpWidget(const SizedBox.shrink());
    await projectListBloc.close();
    await pillarBloc.close();
  }
}
