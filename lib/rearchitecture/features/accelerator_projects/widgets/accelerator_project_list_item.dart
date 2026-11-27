import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_project_details/accelerator_project_details.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/update_phase_stepper/update_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Renders an individual Accelerator project or phase card with live vote
/// breakdown and Pillar voting controls.
class AcceleratorProjectListItem extends StatelessWidget {
  /// Creates an [AcceleratorProjectListItem].
  const AcceleratorProjectListItem({
    required this._acceleratorProject,
    required this._onStepperNotificationSeeMorePressed,
    this._pillarInfo,
    this._activePillarCount,
    this._project,
    this._refreshGeneration = 0,
    this._onPhaseUpdated,
    this._voteBreakdownBloc,
    this._voteProjectBloc,
    super.key,
  });

  final AcceleratorProject _acceleratorProject;
  final PillarInfo? _pillarInfo;
  final int? _activePillarCount;
  final Project? _project;
  final int _refreshGeneration;
  final VoidCallback _onStepperNotificationSeeMorePressed;
  final VoidCallback? _onPhaseUpdated;
  final ProjectVoteBreakdownBloc? _voteBreakdownBloc;
  final VoteProjectBloc? _voteProjectBloc;

  @override
  Widget build(BuildContext context) {
    final ProjectVoteBreakdownBloc? providedBreakdownBloc = _voteBreakdownBloc;
    final VoteProjectBloc? providedVoteBloc = _voteProjectBloc;

    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        if (providedBreakdownBloc != null)
          BlocProvider<ProjectVoteBreakdownBloc>.value(
            value: providedBreakdownBloc,
          )
        else
          BlocProvider<ProjectVoteBreakdownBloc>(
            create: (_) => ProjectVoteBreakdownBloc(zenon: zenon!)
              ..add(
                ProjectVoteBreakdownRequested(
                  pillarName: _pillarInfo?.name,
                  projectId: _acceleratorProject.id,
                ),
              ),
          ),
        if (providedVoteBloc != null)
          BlocProvider<VoteProjectBloc>.value(value: providedVoteBloc)
        else
          BlocProvider<VoteProjectBloc>(
            create: (_) => VoteProjectBloc(
              accountBlockUtils: AccountBlockUtils(),
              zenon: zenon!,
            ),
          ),
      ],
      child: _View(
        acceleratorProject: _acceleratorProject,
        pillarInfo: _pillarInfo,
        activePillarCount: _activePillarCount,
        project: _project,
        refreshGeneration: _refreshGeneration,
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
        onPhaseUpdated: _onPhaseUpdated,
      ),
    );
  }
}

class _View extends StatefulWidget {
  const _View({
    required this._acceleratorProject,
    required this._onStepperNotificationSeeMorePressed,
    this._pillarInfo,
    this._activePillarCount,
    this._project,
    this._refreshGeneration = 0,
    this._onPhaseUpdated,
  });

  final AcceleratorProject _acceleratorProject;
  final PillarInfo? _pillarInfo;
  final int? _activePillarCount;
  final Project? _project;
  final int _refreshGeneration;
  final VoidCallback _onStepperNotificationSeeMorePressed;
  final VoidCallback? _onPhaseUpdated;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  @override
  void didUpdateWidget(covariant _View oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._pillarInfo?.name != widget._pillarInfo?.name ||
        oldWidget._acceleratorProject.id != widget._acceleratorProject.id ||
        oldWidget._refreshGeneration != widget._refreshGeneration) {
      context.read<ProjectVoteBreakdownBloc>().add(
        ProjectVoteBreakdownRequested(
          pillarName: widget._pillarInfo?.name,
          projectId: widget._acceleratorProject.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AcceleratorProject acceleratorProject = widget._acceleratorProject;

    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: acceleratorProject is Project
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => ProjectDetailsScreen(
                    pillarInfo: widget._pillarInfo,
                    activePillarCount: widget._activePillarCount,
                    project: acceleratorProject,
                    onStepperNotificationSeeMorePressed:
                        widget._onStepperNotificationSeeMorePressed,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Column(
          children: <Widget>[
            _buildProjectTitle(context, acceleratorProject),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: AcceleratorProjectMetadata(
                owner: acceleratorProject is Project
                    ? acceleratorProject.owner
                    : null,
                hash: acceleratorProject.id,
                creationTimestamp: acceleratorProject.creationTimestamp,
                acceleratorProjectStatus: acceleratorProject.status,
                isPhase: acceleratorProject is Phase,
              ),
            ),
            const SizedBox(height: 10),
            _buildProjectDescription(context, acceleratorProject),
            const SizedBox(height: 10),
            _buildProjectStatuses(context, acceleratorProject),
            const SizedBox(height: 10),
            _buildVoteBreakdownSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTitle(
    BuildContext context,
    AcceleratorProject acceleratorProject,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            acceleratorProject.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectDescription(
    BuildContext context,
    AcceleratorProject acceleratorProject,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            acceleratorProject.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectStatuses(
    BuildContext context,
    AcceleratorProject acceleratorProject,
  ) {
    final List<Widget> tags = <Widget>[
      _buildProjectStatusTag(context, acceleratorProject.status),
    ];

    if (acceleratorProject.znnFundsNeeded > BigInt.zero) {
      tags.add(
        _ProjectStatusPill(
          text:
              '${acceleratorProject.znnFundsNeeded.addDecimals(coinDecimals)} '
              '${kZnnCoin.symbol}',
          color: Theme.of(context).colorScheme.secondary,
        ),
      );
    }

    if (acceleratorProject.qsrFundsNeeded > BigInt.zero) {
      tags.add(
        _ProjectStatusPill(
          text:
              '${acceleratorProject.qsrFundsNeeded.addDecimals(coinDecimals)} '
              '${kQsrCoin.symbol}',
          color: Theme.of(context).colorScheme.secondary,
        ),
      );
    }

    if (acceleratorProject is Project &&
        acceleratorProject.phases.isNotEmpty &&
        acceleratorProject.phases.last.status ==
            AcceleratorProjectStatus.voting) {
      tags.add(
        _ProjectStatusPill(
          text: context.l10n.phaseNeedsVoting,
          color: AppColors.znnColor.withValues(alpha: 0.7),
        ),
      );
    }

    return Wrap(spacing: 10, runSpacing: 6, children: tags);
  }

  Widget _buildProjectStatusTag(
    BuildContext context,
    AcceleratorProjectStatus status,
  ) {
    return switch (status) {
      AcceleratorProjectStatus.closed => _ProjectStatusPill(
        text: context.l10n.rejected,
        color: AppColors.errorColor,
      ),
      AcceleratorProjectStatus.active => _ProjectStatusPill(
        text: context.l10n.accepted,
        color: AppColors.znnColor,
      ),
      AcceleratorProjectStatus.voting => _ProjectStatusPill(
        text: context.l10n.votingOpen,
        iconData: MaterialCommunityIcons.vote,
        color: AppColors.znnColor.withValues(alpha: 0.7),
      ),
      AcceleratorProjectStatus.paid => _ProjectStatusPill(
        text: context.l10n.paid,
        color: AppColors.alertNotification,
      ),
      AcceleratorProjectStatus.completed => _ProjectStatusPill(
        text: context.l10n.completed,
        color: AppColors.qsrColor,
      ),
    };
  }

  Widget _buildVoteBreakdownSection(BuildContext context) {
    return BlocConsumer<ProjectVoteBreakdownBloc, ProjectVoteBreakdownState>(
      listener: (BuildContext context, ProjectVoteBreakdownState state) {
        if (state is ProjectVoteBreakdownFailure) {
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorGettingVoteBreakdown,
            ),
          );
        }
      },
      builder: (BuildContext context, ProjectVoteBreakdownState state) {
        return switch (state) {
          ProjectVoteBreakdownInitial() ||
          ProjectVoteBreakdownLoading() => const SyriusLoadingWidget(),
          ProjectVoteBreakdownFailure(:final SyriusException exception) =>
            SyriusErrorWidget(exception),
          ProjectVoteBreakdownPopulated(
            :final VoteBreakdown voteBreakdown,
            :final List<PillarVote?>? pillarVotes,
          ) =>
            _buildVotingRow(context, voteBreakdown, pillarVotes),
        };
      },
    );
  }

  Widget _buildVotingRow(
    BuildContext context,
    VoteBreakdown voteBreakdown,
    List<PillarVote?>? pillarVoteList,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Visibility(
          visible: voteBreakdown.total > 0,
          child: _buildVotingResults(context, voteBreakdown),
        ),
        _buildActionIcons(context, pillarVoteList),
      ],
    );
  }

  Widget _buildVotingResults(
    BuildContext context,
    VoteBreakdown voteBreakdown,
  ) {
    final int yesVotes = voteBreakdown.yes;
    final int noVotes = voteBreakdown.no;
    final int decisiveVotes = yesVotes + noVotes;
    final int quorum = voteBreakdown.total;
    final int totalPillars = widget._activePillarCount ?? kNumOfPillars ?? 0;
    final int quorumNeeded = totalPillars > 0
        ? (totalPillars * 33) ~/ 100 + 1
        : 0;
    final int votesToAchieveQuorum = totalPillars > 0
        ? (quorumNeeded - quorum).clamp(0, totalPillars)
        : 0;
    final int pillarsThatCanStillVote = totalPillars > 0
        ? (totalPillars - quorum - votesToAchieveQuorum).clamp(0, totalPillars)
        : 0;
    final double quorumFraction = totalPillars > 0
        ? (quorum / totalPillars).clamp(0.0, 1.0)
        : 0.0;
    final double remainingQuorumFraction = totalPillars > 0
        ? (votesToAchieveQuorum / totalPillars).clamp(0.0, 1.0 - quorumFraction)
        : 0.0;
    final double remainingPillarsFraction = totalPillars > 0
        ? (pillarsThatCanStillVote / totalPillars).clamp(
            0.0,
            1.0 - quorumFraction - remainingQuorumFraction,
          )
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[Text(context.l10n.votingResults)]),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            AcceleratorVotingProgressBar(
              child: Row(
                children: <Widget>[
                  AcceleratorVotingProgressBarSpan(
                    value: decisiveVotes > 0 ? yesVotes / decisiveVotes : 0,
                    color: AppColors.znnColor,
                    tooltipMessage: context.l10n.yesVotesCount(yesVotes),
                  ),
                  AcceleratorVotingProgressBarSpan(
                    value: decisiveVotes > 0 ? noVotes / decisiveVotes : 0,
                    color: AppColors.errorColor,
                    tooltipMessage: context.l10n.noVotesCount(noVotes),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: yesVotes > noVotes
                  ? context.l10n.moreYesThanNoVotes
                  : context.l10n.notEnoughYesVotes,
              child: Icon(
                Icons.check_circle,
                color: yesVotes > noVotes
                    ? AppColors.znnColor
                    : Theme.of(context).colorScheme.secondary,
                size: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (totalPillars > 0)
          Row(
            children: <Widget>[
              AcceleratorVotingProgressBar(
                child: Row(
                  children: <Widget>[
                    AcceleratorVotingProgressBarSpan(
                      value: quorumFraction,
                      color: AppColors.qsrColor,
                      tooltipMessage: context.l10n.totalVotesCount(
                        voteBreakdown.total,
                      ),
                    ),
                    if (votesToAchieveQuorum > 0)
                      AcceleratorVotingProgressBarSpan(
                        value: remainingQuorumFraction,
                        color: AppColors.alertNotification,
                        tooltipMessage: context.l10n.moreVotesNeededForQuorum(
                          votesToAchieveQuorum,
                        ),
                      ),
                    AcceleratorVotingProgressBarSpan(
                      value: remainingPillarsFraction,
                      color: Colors.transparent,
                      tooltipMessage: context.l10n.pillarsCanStillVote(
                        pillarsThatCanStillVote,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: quorum >= quorumNeeded
                    ? context.l10n.quorumAchieved
                    : context.l10n.quorumNotAchieved,
                child: Icon(
                  Icons.check_circle,
                  color: quorum >= quorumNeeded
                      ? AppColors.znnColor
                      : Theme.of(context).colorScheme.secondary,
                  size: 15,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildOpenLinkIcon(BuildContext context) {
    final String url = widget._acceleratorProject.url;
    return RawMaterialButton(
      constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const CircleBorder(),
      onPressed: () {
        unawaited(NavigationUtils.openUrl(url));
      },
      child: Tooltip(
        message: context.l10n.visitDomain(url),
        child: Container(
          height: 50,
          width: 50,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white12,
          ),
          child: const Icon(
            Icons.open_in_new,
            size: 25,
            color: AppColors.znnColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcons(
    BuildContext context,
    List<PillarVote?>? pillarVoteList,
  ) {
    final AcceleratorProject acceleratorProject = widget._acceleratorProject;
    final bool canVote =
        pillarVoteList != null &&
        ((acceleratorProject is Phase &&
                acceleratorProject.status == AcceleratorProjectStatus.active) ||
            acceleratorProject.status == AcceleratorProjectStatus.voting);

    return Row(
      children: <Widget>[
        if (canVote) _buildVoteControls(context, pillarVoteList),
        if (<AcceleratorProjectStatus>[
          AcceleratorProjectStatus.voting,
          AcceleratorProjectStatus.active,
          AcceleratorProjectStatus.paid,
        ].contains(acceleratorProject.status))
          Row(
            children: <Widget>[
              const SizedBox(width: 10),
              _buildOpenLinkIcon(context),
            ],
          ),
        if (acceleratorProject is Phase &&
            acceleratorProject.status == AcceleratorProjectStatus.voting &&
            widget._project != null &&
            widget._project!.owner.toString() == kSelectedAddress)
          Row(
            children: <Widget>[
              const SizedBox(width: 10),
              _buildUpdatePhaseIcon(context, acceleratorProject),
            ],
          ),
      ],
    );
  }

  Widget _buildVoteControls(
    BuildContext context,
    List<PillarVote?> pillarVoteList,
  ) {
    return BlocConsumer<VoteProjectBloc, VoteProjectState>(
      listener: (BuildContext context, VoteProjectState state) {
        if (state is VoteProjectDone) {
          context.read<ProjectVoteBreakdownBloc>().add(
            ProjectVoteBreakdownRequested(
              pillarName: widget._pillarInfo?.name,
              projectId: widget._acceleratorProject.id,
            ),
          );
        } else if (state is VoteProjectFailure) {
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception is NoPillarForAddressException
                  ? context.l10n.addressOwnsOrProducesNoPillar
                  : state.exception,
              context.l10n.errorVotingProject,
            ),
          );
        }
      },
      builder: (BuildContext context, VoteProjectState state) {
        if (state is VoteProjectLoading) {
          return const SyriusLoadingWidget();
        }
        return _buildVotingIcons(context, pillarVoteList);
      },
    );
  }

  Widget _buildVotingIcons(
    BuildContext context,
    List<PillarVote?> pillarVoteList,
  ) {
    return Row(
      children: <Widget>[
        Tooltip(
          message: context.l10n.no.capitalize(),
          child: RawMaterialButton(
            key: const Key('accelerator_vote_no_button'),
            constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
            onPressed: () => _castVote(context, AcceleratorProjectVote.no),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _isOptionVotedByPillar(
                      pillarVoteList,
                      AcceleratorProjectVote.no,
                    )
                    ? AppColors.errorColor
                    : Theme.of(context).colorScheme.secondary,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 35,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: context.l10n.yes.capitalize(),
          child: RawMaterialButton(
            key: const Key('accelerator_vote_yes_button'),
            constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
            onPressed: () => _castVote(context, AcceleratorProjectVote.yes),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _isOptionVotedByPillar(
                      pillarVoteList,
                      AcceleratorProjectVote.yes,
                    )
                    ? AppColors.znnColor
                    : Theme.of(context).colorScheme.secondary,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 35,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: context.l10n.abstain,
          child: RawMaterialButton(
            key: const Key('accelerator_vote_abstain_button'),
            constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
            onPressed: () => _castVote(context, AcceleratorProjectVote.abstain),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _isOptionVotedByPillar(
                      pillarVoteList,
                      AcceleratorProjectVote.abstain,
                    )
                    ? Theme.of(context).primaryColorLight
                    : Theme.of(context).colorScheme.secondary,
              ),
              child: Icon(
                Icons.stop,
                size: 35,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _castVote(BuildContext context, AcceleratorProjectVote vote) {
    final String? selectedAddress = kSelectedAddress;
    if (selectedAddress == null) {
      return;
    }
    context.read<VoteProjectBloc>().add(
      VoteProjectRequested(
        address: Address.parse(selectedAddress),
        id: widget._acceleratorProject.id,
        vote: vote,
      ),
    );
  }

  Widget _buildUpdatePhaseIcon(BuildContext context, Phase phase) {
    return Tooltip(
      message: context.l10n.updatePhase,
      child: RawMaterialButton(
        constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => StepperScreen(
                stepper: UpdatePhaseStepperPage(
                  phase: phase,
                  project: widget._project!,
                  onPhaseUpdated: widget._onPhaseUpdated,
                ),
                onStepperNotificationSeeMorePressed:
                    widget._onStepperNotificationSeeMorePressed,
              ),
            ),
          );
        },
        child: Container(
          height: 50,
          width: 50,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white12,
          ),
          child: const Icon(Icons.edit, size: 25, color: AppColors.znnColor),
        ),
      ),
    );
  }

  bool _isOptionVotedByPillar(
    List<PillarVote?> pillarVoteList,
    AcceleratorProjectVote vote,
  ) {
    final String? pillarName = widget._pillarInfo?.name;
    if (pillarName == null) {
      return false;
    }
    for (final PillarVote? pillarVote in pillarVoteList) {
      if (pillarVote != null && pillarVote.name == pillarName) {
        return pillarVote.vote == vote.index;
      }
    }
    return false;
  }
}

class _ProjectStatusPill extends StatelessWidget {
  const _ProjectStatusPill({
    required this._text,
    required this._color,
    this._iconData,
  });

  final String _text;
  final Color _color;
  final IconData? _iconData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 25,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: _color,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_iconData != null) ...<Widget>[
            Icon(_iconData, color: Colors.white, size: 15),
            const SizedBox(width: 5),
          ],
          Text(_text, style: kBodySmallTextStyle.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
