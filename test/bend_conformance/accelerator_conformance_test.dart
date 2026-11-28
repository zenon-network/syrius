@Tags(<String>['bend'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'bend_conformance_helper.dart';

const String _kDomain = 'accelerator';
final BigInt _kBaseUnit = BigInt.from(100000000);

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class _MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

Address _addr(int seed) {
  final List<int> key = List<int>.filled(32, 0);
  key[0] = seed & 0xff;
  key[1] = (seed >> 8) & 0xff;
  key[31] = (seed * 17 + 5) & 0xff;
  return Address.fromPublicKey(key);
}

Hash _hash(int seed) => Hash.digest(<int>[seed & 0xff, (seed >> 8) & 0xff, 42]);

PillarInfo _pillar({
  required int id,
  required int ownerSeed,
  required int producerSeed,
}) {
  final Address own = _addr(ownerSeed);
  final Address prod = _addr(producerSeed);
  return PillarInfo.fromJson(<String, dynamic>{
    'name': 'pillar_$id',
    'rank': 1,
    'type': PillarInfo.regularPillarType,
    'ownerAddress': own.toString(),
    'producerAddress': prod.toString(),
    'withdrawAddress': own.toString(),
    'giveMomentumRewardPercentage': 0,
    'giveDelegateRewardPercentage': 100,
    'isRevocable': false,
    'revokeCooldown': 0,
    'revokeTimestamp': 0,
    'currentStats': const <String, dynamic>{
      'producedMomentums': 0,
      'expectedMomentums': 0,
    },
    'weight': '0',
  });
}

AcceleratorProjectStatus _parseProjectStatus(String name) {
  return switch (name) {
    'voting' => AcceleratorProjectStatus.voting,
    'active' => AcceleratorProjectStatus.active,
    'paid' => AcceleratorProjectStatus.paid,
    'closed' => AcceleratorProjectStatus.closed,
    'completed' => AcceleratorProjectStatus.completed,
    _ => fail('Unknown AcceleratorProjectStatus "$name"'),
  };
}

Phase _buildPhase({
  required int seed,
  required Hash projectId,
  required AcceleratorProjectStatus status,
  required BigInt znnFunds,
  required BigInt qsrFunds,
}) {
  final Hash phaseId = _hash(seed);
  return Phase.fromJson(<String, dynamic>{
    'phase': <String, dynamic>{
      'id': phaseId.toString(),
      'projectID': projectId.toString(),
      'name': 'Phase $seed',
      'description': 'Phase desc',
      'url': 'https://phase.example.org',
      'znnFundsNeeded': znnFunds.toString(),
      'qsrFundsNeeded': qsrFunds.toString(),
      'creationTimestamp': 100,
      'acceptedTimestamp': 110,
      'status': status.index,
    },
    'votes': <String, dynamic>{
      'id': phaseId.toString(),
      'yes': 1,
      'no': 0,
      'total': 1,
    },
  });
}

Project _buildProject({
  required int seed,
  required Address owner,
  required AcceleratorProjectStatus status,
  required BigInt znnFunds,
  required BigInt qsrFunds,
  List<Phase> phases = const <Phase>[],
}) {
  final Hash id = _hash(seed);
  return Project(
    id: id,
    name: 'Project $seed',
    owner: owner,
    description: 'Project desc',
    url: 'https://project.example.org',
    znnFundsNeeded: znnFunds,
    qsrFundsNeeded: qsrFunds,
    creationTimestamp: 100,
    lastUpdateTimestamp: 200,
    status: status.index,
    phaseIds: phases.map((Phase p) => p.id).toList(),
    voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
      'id': id.toString(),
      'yes': 1,
      'no': 0,
      'total': 1,
    }),
    phases: phases,
  );
}

ProjectList _wrapProjectList(List<Project> items) {
  return ProjectList.fromJson(<String, dynamic>{
    'count': items.length,
    'list': items
        .map(
          (Project p) => <String, dynamic>{
            'id': p.id.toString(),
            'owner': p.owner.toString(),
            'name': p.name,
            'description': p.description,
            'url': p.url,
            'znnFundsNeeded': p.znnFundsNeeded.toString(),
            'qsrFundsNeeded': p.qsrFundsNeeded.toString(),
            'creationTimestamp': p.creationTimestamp,
            'lastUpdateTimestamp': p.lastUpdateTimestamp,
            'status': p.statusInt,
            'votes': p.voteBreakdown.toJson(),
            'phaseIds': p.phaseIds.map((Hash h) => h.toString()).toList(),
            'phases': p.phases
                .map(
                  (Phase ph) => <String, dynamic>{
                    'phase': <String, dynamic>{
                      'id': ph.id.toString(),
                      'projectID': ph.projectId.toString(),
                      'name': ph.name,
                      'description': ph.description,
                      'url': ph.url,
                      'znnFundsNeeded': ph.znnFundsNeeded.toString(),
                      'qsrFundsNeeded': ph.qsrFundsNeeded.toString(),
                      'creationTimestamp': ph.creationTimestamp,
                      'acceptedTimestamp': ph.acceptedTimestamp,
                      'status': ph.statusInt,
                    },
                    'votes': ph.voteBreakdown.toJson(),
                  },
                )
                .toList(),
          },
        )
        .toList(),
  });
}

Future<Map<String, Object>> _evalDonationPartialRetry({
  required int znn,
  required int qsr,
  required bool znnOk,
  required bool qsrOk,
  required bool retryQsrOk,
}) async {
  final _MockZenon zenon = _MockZenon();
  final _MockEmbeddedApi embedded = _MockEmbeddedApi();
  final _MockAcceleratorApi acceleratorApi = _MockAcceleratorApi();
  final _MockAccountBlockUtils blockUtils = _MockAccountBlockUtils();
  final _MockZenonAddressUtils addressUtils = _MockZenonAddressUtils();
  final _MockAccountBlockTemplate znnTpl = _MockAccountBlockTemplate();
  final _MockAccountBlockTemplate qsrTpl = _MockAccountBlockTemplate();
  final _MockAccountBlockTemplate znnBlock = _MockAccountBlockTemplate();
  final _MockAccountBlockTemplate qsrBlock = _MockAccountBlockTemplate();
  final Address donor = _addr(77);

  when(() => zenon.embedded).thenReturn(embedded);
  when(() => embedded.accelerator).thenReturn(acceleratorApi);
  when(addressUtils.refreshBalance).thenReturn(null);

  int znnSentCount = 0;
  int qsrSentCount = 0;
  bool currentZnnOk = znnOk;
  bool currentQsrOk = qsrOk;

  when(
    () => acceleratorApi.donate(any(), kZnnCoin.tokenStandard),
  ).thenReturn(znnTpl);
  when(
    () => acceleratorApi.donate(any(), kQsrCoin.tokenStandard),
  ).thenReturn(qsrTpl);
  when(
    () => blockUtils.createAccountBlock(
      znnTpl,
      'donate for accelerator',
      address: donor,
    ),
  ).thenAnswer((_) async {
    if (!currentZnnOk) {
      throw Exception('znn failed');
    }
    znnSentCount += 1;
    return znnBlock;
  });
  when(
    () => blockUtils.createAccountBlock(
      qsrTpl,
      'donate for accelerator',
      address: donor,
    ),
  ).thenAnswer((_) async {
    if (!currentQsrOk) {
      throw Exception('qsr failed');
    }
    qsrSentCount += 1;
    return qsrBlock;
  });

  final SubmitDonationBloc bloc = SubmitDonationBloc(
    accountBlockUtils: blockUtils,
    zenon: zenon,
    zenonAddressUtils: addressUtils,
  );

  final Future<SubmitDonationState> firstDone = bloc.stream.firstWhere(
    (SubmitDonationState s) =>
        s is SubmitDonationDone || s is SubmitDonationFailure,
  );
  bloc.add(
    SubmitDonationRequested(
      address: donor,
      znnAmount: BigInt.from(znn),
      qsrAmount: BigInt.from(qsr),
    ),
  );
  final SubmitDonationState firstState = await firstDone;

  final bool firstSentZnn = znnSentCount > 0;
  final bool firstSentQsr = qsrSentCount > 0;
  final bool firstZnnSubmittedFlag =
      firstState is SubmitDonationFailure && firstState.znnSubmitted;

  bool retrySentZnn = false;
  bool retrySentQsr = false;
  bool finalSubmitted = firstState is SubmitDonationDone;

  if (firstState is SubmitDonationFailure && firstState.znnSubmitted) {
    final int znnBeforeRetry = znnSentCount;
    final int qsrBeforeRetry = qsrSentCount;
    currentZnnOk = true;
    currentQsrOk = retryQsrOk;

    final Future<SubmitDonationState> retryDone = bloc.stream.firstWhere(
      (SubmitDonationState s) =>
          s is SubmitDonationDone || s is SubmitDonationFailure,
    );
    // Matches AcceleratorDonationStepperView: clears ZNN amount to 0 when
    // znnSubmitted is true so retry only submits the QSR leg.
    bloc.add(
      SubmitDonationRequested(
        address: donor,
        znnAmount: BigInt.zero,
        qsrAmount: BigInt.from(qsr),
      ),
    );
    final SubmitDonationState retryState = await retryDone;
    retrySentZnn = znnSentCount > znnBeforeRetry;
    retrySentQsr = qsrSentCount > qsrBeforeRetry;
    finalSubmitted = retryState is SubmitDonationDone;
  }

  await bloc.close();

  return <String, Object>{
    'first_sent_znn': firstSentZnn,
    'first_sent_qsr': firstSentQsr,
    'first_znn_submitted_flag': firstZnnSubmittedFlag,
    'retry_sent_znn': retrySentZnn,
    'retry_sent_qsr': retrySentQsr,
    'final_submitted': finalSubmitted,
  };
}

Future<Map<String, Object>> _evalProjectListFilter({
  required bool hasPillar,
  required AcceleratorProjectStatus status,
  required bool isOwner,
  required bool tagMyProjects,
  required bool tagOnlyAccepted,
  required bool tagNeedsVoting,
  required bool tagAlreadyVoted,
  required bool hasVoted,
}) async {
  final _MockZenon zenon = _MockZenon();
  final _MockEmbeddedApi embedded = _MockEmbeddedApi();
  final _MockAcceleratorApi acceleratorApi = _MockAcceleratorApi();
  final Address myAddr = _addr(1);
  final Address otherAddr = _addr(2);
  final PillarInfo pillar = _pillar(id: 1, ownerSeed: 1, producerSeed: 3);
  final Project project = _buildProject(
    seed: 11,
    owner: isOwner ? myAddr : otherAddr,
    status: status,
    znnFunds: BigInt.from(100) * _kBaseUnit,
    qsrFunds: BigInt.from(1000) * _kBaseUnit,
  );

  when(() => zenon.embedded).thenReturn(embedded);
  when(() => embedded.accelerator).thenReturn(acceleratorApi);
  when(
    () => acceleratorApi.getAll(
      pageIndex: any(named: 'pageIndex'),
      pageSize: any(named: 'pageSize'),
    ),
  ).thenAnswer((_) async => _wrapProjectList(<Project>[project]));
  when(
    () => acceleratorApi.getPillarVotes(any(), any()),
  ).thenAnswer((Invocation inv) async {
    final List<String> ids = inv.positionalArguments[1] as List<String>;
    if (!hasVoted || !ids.contains(project.id.toString())) {
      return <PillarVote?>[];
    }
    return <PillarVote?>[
      PillarVote.fromJson(<String, dynamic>{
        'id': project.id.toString(),
        'name': pillar.name,
        'vote': AcceleratorProjectVote.yes.index,
      }),
    ];
  });

  // Start with pillarInfo so voting tags can be toggled, then simulate pillar
  // loss via ProjectListPillarUpdated(pillarInfo: null) when !hasPillar.
  final ProjectListBloc bloc = ProjectListBloc(
    zenon: zenon,
    pillarInfo: pillar,
    walletAddressesProvider: () => <String>[myAddr.toString()],
    listenToWsReconnect: false,
  );

  Future<ProjectListState> waitPopulated() => bloc.stream.firstWhere(
    (ProjectListState s) => s.status == ProjectListStatus.populated,
  );

  Future<ProjectListState> pending = waitPopulated();
  bloc.add(const ProjectListRequested());
  await pending;

  if (tagMyProjects) {
    pending = waitPopulated();
    bloc.add(
      const ProjectListFilterTagToggled(
        tag: AcceleratorProjectFilterTag.myProjects,
      ),
    );
    await pending;
  }
  if (tagOnlyAccepted) {
    pending = waitPopulated();
    bloc.add(
      const ProjectListFilterTagToggled(
        tag: AcceleratorProjectFilterTag.onlyAccepted,
      ),
    );
    await pending;
  }
  if (tagNeedsVoting) {
    pending = waitPopulated();
    bloc.add(
      const ProjectListFilterTagToggled(
        tag: AcceleratorProjectFilterTag.needsVoting,
      ),
    );
    await pending;
  }
  if (tagAlreadyVoted) {
    pending = waitPopulated();
    bloc.add(
      const ProjectListFilterTagToggled(
        tag: AcceleratorProjectFilterTag.alreadyVoted,
      ),
    );
    await pending;
  }

  if (!hasPillar) {
    pending = waitPopulated();
    bloc.add(const ProjectListPillarUpdated(pillarInfo: null));
    await pending;
  }

  final ProjectListState finalState = bloc.state;
  await bloc.close();

  return <String, Object>{
    'visible': finalState.projects.isNotEmpty,
    'needs_voting_kept': finalState.selectedTags.contains(
      AcceleratorProjectFilterTag.needsVoting,
    ),
    'already_voted_kept': finalState.selectedTags.contains(
      AcceleratorProjectFilterTag.alreadyVoted,
    ),
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyAddress);
    registerFallbackValue(BigInt.zero);
    registerFallbackValue(znnZts);
    registerFallbackValue(<String>[]);
  });

  group('Bend conformance: $_kDomain', () {
    test(
      'all Bend oracle vectors match Syrius Accelerator-Z production logic',
      () async {
        final List<Map<String, dynamic>> vectors = loadBendVectors(_kDomain);
        final AppLocalizationsEn l10n = AppLocalizationsEn();
        final Set<String> seenOps = <String>{};

        for (final Map<String, dynamic> vector in vectors) {
          final String caseId = requireCaseId(vector);
          final String op = requireOp(vector);
          final Map<String, dynamic> args = requireArgs(vector);
          final Object? expected = vector['expected'];
          seenOps.add(op);

          switch (op) {
            case 'pillar_resolve':
              final Object? rawPillars = args['pillars'];
              if (rawPillars is! List<dynamic>) {
                fail('Expected List for "pillars" in $args');
              }
              final List<PillarInfo> pillars = <PillarInfo>[];
              for (final Object? entry in rawPillars) {
                if (entry is! Map<String, dynamic>) {
                  fail('Expected Map entry in "pillars": $entry');
                }
                pillars.add(
                  _pillar(
                    id: requireInt(entry, 'id'),
                    ownerSeed: requireInt(entry, 'owner'),
                    producerSeed: requireInt(entry, 'producer'),
                  ),
                );
              }
              final Address queryAddr = _addr(requireInt(args, 'addr'));
              final PillarInfo? resolved = pillarForAddress(pillars, queryAddr);
              final int? foundId = resolved == null
                  ? null
                  : int.parse(resolved.name.replaceFirst('pillar_', ''));
              final String voteMethod = resolved == null
                  ? 'none'
                  : switch (voteMethodFor(resolved, queryAddr)) {
                      AcceleratorVoteMethod.byName => 'by_name',
                      AcceleratorVoteMethod.byProdAddress => 'by_prod_address',
                    };

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object?>{
                  'found_id': foundId,
                  'vote_method': voteMethod,
                },
                expected: expected,
              );

            case 'vote_summary':
              final int yes = requireInt(args, 'yes');
              final int no = requireInt(args, 'no');
              final int abstain = requireInt(args, 'abstain');
              final int totalPillars = requireInt(args, 'total_pillars');
              final AcceleratorVoteSummary summary =
                  computeAcceleratorVoteSummary(
                    yes: yes,
                    no: no,
                    total: yes + no + abstain,
                    totalPillars: totalPillars,
                  );

              final double barSum =
                  summary.quorumFraction +
                  summary.remainingQuorumFraction +
                  summary.remainingPillarsFraction;
              final bool barConserved =
                  !barSum.isNaN &&
                  !barSum.isInfinite &&
                  barSum >= 0.0 &&
                  barSum <= 1.0 + 1e-12;

              expectBendMatch(
                domain: _kDomain,
                caseId: '$caseId/bar_conserved',
                actual: barConserved,
                expected: true,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'quorum_needed': summary.quorumNeeded,
                  'quorum_reached': summary.quorumReached,
                  'has_majority': summary.hasMajority,
                },
                expected: expected,
              );

            case 'donation_valid':
              final int znn = requireInt(args, 'znn');
              final int qsr = requireInt(args, 'qsr');
              final int balZnn = requireInt(args, 'bal_znn');
              final int balQsr = requireInt(args, 'bal_qsr');
              final BigInt znnBase = BigInt.from(znn) * _kBaseUnit;
              final BigInt qsrBase = BigInt.from(qsr) * _kBaseUnit;
              final BigInt balZnnBase = BigInt.from(balZnn) * _kBaseUnit;
              final BigInt balQsrBase = BigInt.from(balQsr) * _kBaseUnit;

              final bool blocAmountsValid = isValidDonationAmounts(
                znnAmount: znnBase,
                qsrAmount: qsrBase,
              );
              final bool actual =
                  blocAmountsValid &&
                  znnBase <= balZnnBase &&
                  qsrBase <= balQsrBase;

              if (znn >= 0 && qsr >= 0) {
                final String? znnErr = validateAcceleratorAmount(
                  value: znn.toString(),
                  maxValue: balZnnBase,
                  decimals: coinDecimals,
                  minValue: BigInt.zero,
                  canBeBlank: true,
                  l10n: l10n,
                );
                final String? qsrErr = validateAcceleratorAmount(
                  value: qsr.toString(),
                  maxValue: balQsrBase,
                  decimals: coinDecimals,
                  minValue: BigInt.zero,
                  canBeBlank: true,
                  l10n: l10n,
                );
                final bool formValid =
                    znnErr == null &&
                    qsrErr == null &&
                    (znn > 0 || qsr > 0);
                expectBendMatch(
                  domain: _kDomain,
                  caseId: '$caseId/form_agrees_with_bloc',
                  actual: formValid,
                  expected: actual,
                );
              }

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'donation_partial_retry':
              final int znn = requireInt(args, 'znn');
              final int qsr = requireInt(args, 'qsr');
              final bool znnOk = requireBool(args, 'znn_ok');
              final bool qsrOk = requireBool(args, 'qsr_ok');
              final bool retryQsrOk = requireBool(args, 'retry_qsr_ok');

              final Map<String, Object> actual =
                  await _evalDonationPartialRetry(
                    znn: znn,
                    qsr: qsr,
                    znnOk: znnOk,
                    qsrOk: qsrOk,
                    retryQsrOk: retryQsrOk,
                  );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'project_list_filter':
              final bool hasPillar = requireBool(args, 'has_pillar');
              final AcceleratorProjectStatus status = _parseProjectStatus(
                requireString(args, 'status'),
              );
              final bool isOwner = requireBool(args, 'is_owner');
              final bool tagMyProjects = requireBool(args, 'tag_my_projects');
              final bool tagOnlyAccepted = requireBool(
                args,
                'tag_only_accepted',
              );
              final bool tagNeedsVoting = requireBool(args, 'tag_needs_voting');
              final bool tagAlreadyVoted = requireBool(
                args,
                'tag_already_voted',
              );
              final bool hasVoted = requireBool(args, 'has_voted');

              final Map<String, Object> actual = await _evalProjectListFilter(
                hasPillar: hasPillar,
                status: status,
                isOwner: isOwner,
                tagMyProjects: tagMyProjects,
                tagOnlyAccepted: tagOnlyAccepted,
                tagNeedsVoting: tagNeedsVoting,
                tagAlreadyVoted: tagAlreadyVoted,
                hasVoted: hasVoted,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'project_budget_and_phase':
              final int ownerZnnBal = requireInt(args, 'owner_znn_bal');
              final int znnNeeded = requireInt(args, 'znn_needed');
              final int qsrNeeded = requireInt(args, 'qsr_needed');
              final int paidZnn = requireInt(args, 'paid_znn');
              final int paidQsr = requireInt(args, 'paid_qsr');
              final int phaseZnn = requireInt(args, 'phase_znn');
              final int phaseQsr = requireInt(args, 'phase_qsr');

              final BigInt ownerBalBase = BigInt.from(ownerZnnBal) * _kBaseUnit;
              final BigInt totalZnnBase = BigInt.from(znnNeeded) * _kBaseUnit;
              final BigInt totalQsrBase = BigInt.from(qsrNeeded) * _kBaseUnit;
              final BigInt paidZnnBase = BigInt.from(paidZnn) * _kBaseUnit;
              final BigInt paidQsrBase = BigInt.from(paidQsr) * _kBaseUnit;

              final bool validProject =
                  ownerBalBase >= projectCreationFeeInZnn &&
                  totalZnnBase >= kZnnProjectMinimumFunds &&
                  totalZnnBase <= kZnnProjectMaximumFunds &&
                  totalQsrBase >= kQsrProjectMinimumFunds &&
                  totalQsrBase <= kQsrProjectMaximumFunds;

              final Hash projId = _hash(88);
              final List<Phase> phases = (paidZnn > 0 || paidQsr > 0)
                  ? <Phase>[
                      _buildPhase(
                        seed: 89,
                        projectId: projId,
                        status: AcceleratorProjectStatus.paid,
                        znnFunds: paidZnnBase,
                        qsrFunds: paidQsrBase,
                      ),
                    ]
                  : const <Phase>[];
              final Project project = _buildProject(
                seed: 88,
                owner: _addr(1),
                status: AcceleratorProjectStatus.active,
                znnFunds: totalZnnBase,
                qsrFunds: totalQsrBase,
                phases: phases,
              );

              final BigInt remZnnBase = project.getRemainingZnnFunds();
              final BigInt remQsrBase = project.getRemainingQsrFunds();
              final int remZnn = (remZnnBase <= BigInt.zero
                  ? BigInt.zero
                  : remZnnBase ~/ _kBaseUnit)
                  .toInt();
              final int remQsr = (remQsrBase <= BigInt.zero
                  ? BigInt.zero
                  : remQsrBase ~/ _kBaseUnit)
                  .toInt();

              if (paidZnn <= znnNeeded && paidQsr <= qsrNeeded) {
                expectBendMatch(
                  domain: _kDomain,
                  caseId: '$caseId/znn_conservation',
                  actual: (project.getPaidZnnFunds() + remZnnBase).toString(),
                  expected: totalZnnBase.toString(),
                );
                expectBendMatch(
                  domain: _kDomain,
                  caseId: '$caseId/qsr_conservation',
                  actual: (project.getPaidQsrFunds() + remQsrBase).toString(),
                  expected: totalQsrBase.toString(),
                );
              }

              final String? phaseZnnErr = validateAcceleratorAmount(
                value: phaseZnn.toString(),
                maxValue: remZnnBase < BigInt.zero ? BigInt.zero : remZnnBase,
                decimals: coinDecimals,
                minValue: BigInt.zero,
                l10n: l10n,
              );
              final String? phaseQsrErr = validateAcceleratorAmount(
                value: phaseQsr.toString(),
                maxValue: remQsrBase < BigInt.zero ? BigInt.zero : remQsrBase,
                decimals: coinDecimals,
                minValue: BigInt.zero,
                l10n: l10n,
              );
              final bool validPhase =
                  phaseZnnErr == null && phaseQsrErr == null;

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'valid_project': validProject,
                  'remaining_znn': remZnn,
                  'remaining_qsr': remQsr,
                  'valid_phase': validPhase,
                },
                expected: expected,
              );

            case 'phase_gate':
              final bool isOwner = requireBool(args, 'is_owner');
              final AcceleratorProjectStatus projStatus = _parseProjectStatus(
                requireString(args, 'project_status'),
              );
              final String lastPhaseStr = requireString(
                args,
                'last_phase_status',
              );
              final AcceleratorProjectStatus phaseStatus = _parseProjectStatus(
                requireString(args, 'phase_status'),
              );

              final Hash projId = _hash(91);
              final List<Phase> phases = lastPhaseStr == 'none'
                  ? const <Phase>[]
                  : <Phase>[
                      _buildPhase(
                        seed: 92,
                        projectId: projId,
                        status: _parseProjectStatus(lastPhaseStr),
                        znnFunds: BigInt.zero,
                        qsrFunds: BigInt.zero,
                      ),
                    ];
              final Project project = _buildProject(
                seed: 91,
                owner: _addr(1),
                status: projStatus,
                znnFunds: BigInt.from(100) * _kBaseUnit,
                qsrFunds: BigInt.from(1000) * _kBaseUnit,
                phases: phases,
              );
              final Phase targetPhase = _buildPhase(
                seed: 93,
                projectId: projId,
                status: phaseStatus,
                znnFunds: BigInt.zero,
                qsrFunds: BigInt.zero,
              );

              final bool canCreate =
                  isOwner &&
                  project.status == AcceleratorProjectStatus.active &&
                  (project.phases.isEmpty ||
                      project.phases.last.status ==
                          AcceleratorProjectStatus.paid);
              final bool canUpdate =
                  isOwner &&
                  targetPhase.status == AcceleratorProjectStatus.voting;

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'can_create': canCreate,
                  'can_update': canUpdate,
                },
                expected: expected,
              );

            default:
              fail('Unhandled Bend conformance op "$_kDomain/$op"');
          }
        }

        expect(seenOps, isNotEmpty);
      },
    );
  });
}
