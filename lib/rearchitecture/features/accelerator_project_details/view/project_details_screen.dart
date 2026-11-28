import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_project_details/accelerator_project_details.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_phase_stepper/create_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/refresh_button/refresh_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/update_phase_stepper/update_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays detailed funding stats, phase management, and Pillar voting for an
/// Accelerator-Z project (Screen 29).
class ProjectDetailsScreen extends StatelessWidget {
  /// Creates a [ProjectDetailsScreen].
  const ProjectDetailsScreen({
    required this._project,
    required this._pillarInfo,
    required this._onStepperNotificationSeeMorePressed,
    this._activePillarCount,
    this._refreshProjectBloc,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final AcceleratorProject _project;
  final PillarInfo? _pillarInfo;
  final int? _activePillarCount;
  final RefreshProjectBloc? _refreshProjectBloc;

  @override
  Widget build(BuildContext context) {
    final RefreshProjectBloc? providedBloc = _refreshProjectBloc;
    final Widget view = _View(
      pillarInfo: _pillarInfo,
      activePillarCount: _activePillarCount,
      onStepperNotificationSeeMorePressed: _onStepperNotificationSeeMorePressed,
    );

    if (providedBloc != null) {
      return BlocProvider<RefreshProjectBloc>.value(
        value: providedBloc,
        child: view,
      );
    }

    return BlocProvider<RefreshProjectBloc>(
      create: (_) =>
          RefreshProjectBloc(zenon: zenon!)
            ..add(RefreshProjectRequested(projectId: _project.id)),
      child: view,
    );
  }
}

class _View extends StatefulWidget {
  const _View({
    required this._pillarInfo,
    required this._onStepperNotificationSeeMorePressed,
    this._activePillarCount,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final PillarInfo? _pillarInfo;
  final int? _activePillarCount;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  Project? _lastProject;
  int _refreshGeneration = 0;
  Hash? _selectedPhaseId;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;

    return Scaffold(
      backgroundColor: tokens.shellBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              NotificationWidget(
                onSeeMorePressed: widget._onStepperNotificationSeeMorePressed,
              ),
              Expanded(
                child: BlocConsumer<RefreshProjectBloc, RefreshProjectState>(
                  listener: (BuildContext context, RefreshProjectState state) {
                    if (state is RefreshProjectPopulated &&
                        _lastProject != null) {
                      setState(() {
                        _refreshGeneration++;
                      });
                    } else if (state is RefreshProjectFailure) {
                      _lastProject = null;
                    }
                  },
                  builder: (BuildContext context, RefreshProjectState state) {
                    if (state is RefreshProjectPopulated) {
                      _lastProject = state.project;
                      return _buildScreenLayout(context, tokens, state.project);
                    }
                    if (state is RefreshProjectLoading &&
                        _lastProject != null) {
                      return _buildScreenLayout(context, tokens, _lastProject!);
                    }
                    return switch (state) {
                      RefreshProjectInitial() ||
                      RefreshProjectLoading() => const SyriusLoadingWidget(),
                      RefreshProjectFailure(:final SyriusException exception) =>
                        SyriusErrorWidget(exception),
                      RefreshProjectPopulated(:final Project project) =>
                        _buildScreenLayout(context, tokens, project),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenLayout(
    BuildContext context,
    SyriusThemeTokens tokens,
    Project project,
  ) {
    final bool isProjectOwner = project.owner.toString() == kSelectedAddress;
    final bool canCreatePhase =
        isProjectOwner &&
        project.status == AcceleratorProjectStatus.active &&
        (project.phases.isEmpty ||
            project.phases.last.status == AcceleratorProjectStatus.paid);
    final int totalPillars = widget._activePillarCount ?? kNumOfPillars ?? 0;
    final int quorumNeeded = totalPillars > 0
        ? (totalPillars * 33) ~/ 100 + 1
        : 33;

    Phase? activePhase;
    if (project.phases.isNotEmpty) {
      if (_selectedPhaseId != null) {
        for (final Phase p in project.phases) {
          if (p.id == _selectedPhaseId) {
            activePhase = p;
            break;
          }
        }
      }
      activePhase ??= project.phases.last;
    }

    final AcceleratorProject voteTarget =
        (activePhase != null &&
            activePhase.status == AcceleratorProjectStatus.voting)
        ? activePhase
        : project;

    void refreshProject() {
      if (context.mounted) {
        context.read<RefreshProjectBloc>().add(
          RefreshProjectRequested(projectId: project.id),
        );
      }
    }

    return SyriusCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeaderBar(context, tokens, project, refreshProject),
          Divider(height: 1, color: tokens.border),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildProjectMetadata(context, tokens, project),
                        const SizedBox(height: 16),
                        Text(
                          project.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildPhasesCard(
                          context,
                          tokens,
                          project: project,
                          isProjectOwner: isProjectOwner,
                          canCreatePhase: canCreatePhase,
                          quorumNeeded: quorumNeeded,
                          selectedPhase: activePhase,
                          refreshProject: refreshProject,
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: tokens.border),
                SizedBox(
                  width: 310,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _ProjectVotingSidebar(
                      key: ValueKey<String>(
                        '${voteTarget.id}_$_refreshGeneration',
                      ),
                      target: voteTarget,
                      phaseNumber: activePhase != null
                          ? project.phases.indexOf(activePhase) + 1
                          : null,
                      pillarInfo: widget._pillarInfo,
                      quorumNeeded: quorumNeeded,
                      onVoted: refreshProject,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(
    BuildContext context,
    SyriusThemeTokens tokens,
    Project project,
    VoidCallback refreshProject,
  ) {
    final String explorerUrl = '${kExplorer}project/${project.id}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: <Widget>[
          SyriusGhostButton(
            label: context.l10n.projects,
            icon: Icons.chevron_left,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              project.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildStatusBadge(context, project.status),
          const Spacer(),
          if (project.url.isNotEmpty) ...<Widget>[
            SyriusGhostButton(
              label: context.l10n.article,
              icon: Icons.open_in_new,
              onPressed: () => unawaited(NavigationUtils.openUrl(project.url)),
            ),
            const SizedBox(width: 8),
          ],
          SyriusGhostButton(
            label: context.l10n.explorer,
            icon: Icons.open_in_new,
            onPressed: () => unawaited(NavigationUtils.openUrl(explorerUrl)),
          ),
          const SizedBox(width: 6),
          BlocRefreshLoadingBuilder<RefreshProjectBloc, RefreshProjectState>(
            isLoading: (RefreshProjectState state) =>
                state is RefreshProjectLoading,
            builder:
                (BuildContext context, ValueListenable<bool> isRefreshLoading) {
                  return RefreshButton(
                    isLoadingListenable: isRefreshLoading,
                    onPressed: refreshProject,
                  );
                },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectMetadata(
    BuildContext context,
    SyriusThemeTokens tokens,
    Project project,
  ) {
    final DateTime created = DateTime.fromMillisecondsSinceEpoch(
      project.creationTimestamp * 1000,
    );
    return Wrap(
      spacing: 32,
      runSpacing: 12,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.budget.toUpperCase(),
              style: tokens.microLabelStyle(),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: tokens.monoStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
                children: <InlineSpan>[
                  TextSpan(
                    text:
                        '${project.znnFundsNeeded.addDecimals(coinDecimals)} '
                        '${kZnnCoin.symbol}',
                  ),
                  TextSpan(
                    text:
                        ' · ${project.qsrFundsNeeded.addDecimals(coinDecimals)}'
                        ' ${kQsrCoin.symbol}',
                    style: tokens.monoStyle(
                      fontSize: 13.5,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.owner.toUpperCase(),
              style: tokens.microLabelStyle(),
            ),
            const SizedBox(height: 6),
            Text(
              project.owner.toShortString(),
              style: tokens.monoStyle(color: tokens.textPrimary),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.created.toUpperCase(),
              style: tokens.microLabelStyle(),
            ),
            const SizedBox(height: 6),
            Text(
              _dateFormat.format(created),
              style: tokens.monoStyle(color: tokens.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhasesCard(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required Project project,
    required bool isProjectOwner,
    required bool canCreatePhase,
    required int quorumNeeded,
    required Phase? selectedPhase,
    required VoidCallback refreshProject,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: <Widget>[
                Text(
                  context.l10n.phases,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${project.phases.length}',
                  style: tokens.monoStyle(
                    fontSize: 12.5,
                    color: tokens.textMuted,
                  ),
                ),
                const Spacer(),
                if (isProjectOwner)
                  SyriusPillButton(
                    label: context.l10n.createPhase,
                    compact: true,
                    onPressed: canCreatePhase
                        ? () => _openCreatePhase(
                            context,
                            project,
                            refreshProject,
                          )
                        : null,
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          if (project.phases.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.l10n.projectHasNoPhases,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: tokens.textMuted),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: project.phases.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: tokens.border),
              itemBuilder: (BuildContext context, int index) {
                final Phase phase = project.phases[index];
                final bool isSelected = selectedPhase?.id == phase.id;
                final VoteBreakdown v = phase.voteBreakdown;
                final int abstain = (v.total - v.yes - v.no).clamp(0, 1 << 20);
                return InkWell(
                  onTap: () => setState(() => _selectedPhaseId = phase.id),
                  child: Container(
                    color: isSelected
                        ? tokens.surfaceElevated.withValues(alpha: 0.45)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${index + 1} · ${phase.name}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              if (phase.url.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 2),
                                Text(
                                  phase.url,
                                  overflow: TextOverflow.ellipsis,
                                  style: tokens.monoStyle(
                                    fontSize: 11.5,
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Builder(
                            builder: (_) {
                              final String znnTxt = phase.znnFundsNeeded
                                  .addDecimals(coinDecimals);
                              final String qsrTxt = phase.qsrFundsNeeded
                                  .addDecimals(coinDecimals);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    '$znnTxt ${kZnnCoin.symbol}',
                                    style: tokens.monoStyle(
                                      fontSize: 12.5,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '$qsrTxt ${kQsrCoin.symbol}',
                                    style: tokens.monoStyle(
                                      fontSize: 11.5,
                                      color: tokens.textMuted,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 110,
                          child: Text(
                            '${v.yes} · ${v.no} · $abstain',
                            textAlign: TextAlign.center,
                            style: tokens.monoStyle(
                              fontSize: 11.5,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(context, phase.status),
                        if (isProjectOwner &&
                            phase.status == AcceleratorProjectStatus.voting)
                          IconButton(
                            tooltip: context.l10n.updatePhase,
                            iconSize: 15,
                            splashRadius: 16,
                            color: tokens.textMuted,
                            onPressed: () => _openUpdatePhase(
                              context,
                              project,
                              phase,
                              refreshProject,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openCreatePhase(
    BuildContext context,
    Project project,
    VoidCallback refreshProject,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => StepperScreen(
          breadcrumbParent: project.name,
          title: ctx.l10n.createPhase,
          stepper: CreatePhaseStepperPage(
            project: project,
            onPhaseCreated: refreshProject,
          ),
          onStepperNotificationSeeMorePressed:
              widget._onStepperNotificationSeeMorePressed,
        ),
      ),
    );
  }

  void _openUpdatePhase(
    BuildContext context,
    Project project,
    Phase phase,
    VoidCallback refreshProject,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => StepperScreen(
          breadcrumbParent: project.name,
          title: ctx.l10n.updatePhase,
          stepper: UpdatePhaseStepperPage(
            phase: phase,
            project: project,
            onPhaseUpdated: refreshProject,
          ),
          onStepperNotificationSeeMorePressed:
              widget._onStepperNotificationSeeMorePressed,
        ),
      ),
    );
  }

  SyriusStatusBadge _buildStatusBadge(
    BuildContext context,
    AcceleratorProjectStatus status,
  ) {
    return switch (status) {
      AcceleratorProjectStatus.paid => SyriusStatusBadge(
        label: context.l10n.paid,
        tone: SyriusBadgeTone.success,
        icon: Icons.check,
      ),
      AcceleratorProjectStatus.active => SyriusStatusBadge(
        label: context.l10n.accepted,
        tone: SyriusBadgeTone.success,
        icon: Icons.check,
      ),
      AcceleratorProjectStatus.voting => SyriusStatusBadge(
        label: context.l10n.votingLabel,
        tone: SyriusBadgeTone.info,
        icon: Icons.schedule,
      ),
      AcceleratorProjectStatus.completed => SyriusStatusBadge(
        label: context.l10n.completed,
        tone: SyriusBadgeTone.info,
      ),
      AcceleratorProjectStatus.closed => SyriusStatusBadge(
        label: context.l10n.rejected,
        tone: SyriusBadgeTone.error,
      ),
    };
  }
}

class _ProjectVotingSidebar extends StatelessWidget {
  const _ProjectVotingSidebar({
    required this.target,
    required this.phaseNumber,
    required this.pillarInfo,
    required this.quorumNeeded,
    required this.onVoted,
    super.key,
  });

  final AcceleratorProject target;
  final int? phaseNumber;
  final PillarInfo? pillarInfo;
  final int quorumNeeded;
  final VoidCallback onVoted;

  @override
  Widget build(BuildContext context) {
    final Zenon? znn = zenon;
    if (znn == null) {
      return _buildTallyCard(
        context,
        context.syriusTheme,
        target.voteBreakdown,
      );
    }

    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<ProjectVoteBreakdownBloc>(
          create: (_) => ProjectVoteBreakdownBloc(zenon: znn)
            ..add(
              ProjectVoteBreakdownRequested(
                pillarName: pillarInfo?.name,
                projectId: target.id,
              ),
            ),
        ),
        BlocProvider<VoteProjectBloc>(
          create: (_) => VoteProjectBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: znn,
          ),
        ),
      ],
      child: _ProjectVotingSidebarView(
        target: target,
        phaseNumber: phaseNumber,
        pillarInfo: pillarInfo,
        quorumNeeded: quorumNeeded,
        onVoted: onVoted,
      ),
    );
  }

  Widget _buildTallyCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    VoteBreakdown votes,
  ) {
    final int abstain = (votes.total - votes.yes - votes.no).clamp(0, 1 << 20);
    final double progress = quorumNeeded > 0
        ? (votes.total / quorumNeeded).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _tallyRow(tokens, context.l10n.yes.capitalize(), '${votes.yes}'),
          const SizedBox(height: 8),
          _tallyRow(tokens, context.l10n.no.capitalize(), '${votes.no}'),
          const SizedBox(height: 8),
          _tallyRow(tokens, context.l10n.abstain, '$abstain'),
          const SizedBox(height: 12),
          Divider(height: 1, color: tokens.border),
          const SizedBox(height: 12),
          _tallyRow(
            tokens,
            context.l10n.quorum,
            '${votes.total} of $quorumNeeded',
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: tokens.border,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.znnGreen),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.needsQuorumAndMoreYes(quorumNeeded),
            style: TextStyle(fontSize: 11.5, color: tokens.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _tallyRow(SyriusThemeTokens tokens, String label, String value) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: tokens.monoStyle(
            fontWeight: FontWeight.w500,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ProjectVotingSidebarView extends StatelessWidget {
  const _ProjectVotingSidebarView({
    required this.target,
    required this.phaseNumber,
    required this.pillarInfo,
    required this.quorumNeeded,
    required this.onVoted,
  });

  final AcceleratorProject target;
  final int? phaseNumber;
  final PillarInfo? pillarInfo;
  final int quorumNeeded;
  final VoidCallback onVoted;

  void _castVote(BuildContext context, AcceleratorProjectVote vote) {
    final String? address = kSelectedAddress;
    if (address == null) {
      return;
    }
    context.read<VoteProjectBloc>().add(
      VoteProjectRequested(
        address: Address.parse(address),
        id: target.id,
        vote: vote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final bool canVote =
        pillarInfo != null && target.status == AcceleratorProjectStatus.voting;

    return BlocConsumer<VoteProjectBloc, VoteProjectState>(
      listener: (BuildContext context, VoteProjectState state) {
        if (state is VoteProjectDone) {
          context.read<ProjectVoteBreakdownBloc>().add(
            ProjectVoteBreakdownRequested(
              pillarName: pillarInfo?.name,
              projectId: target.id,
            ),
          );
          onVoted();
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
      builder: (BuildContext context, VoteProjectState voteState) {
        return BlocBuilder<ProjectVoteBreakdownBloc, ProjectVoteBreakdownState>(
          builder: (BuildContext context, ProjectVoteBreakdownState state) {
            final VoteBreakdown votes = switch (state) {
              ProjectVoteBreakdownPopulated(
                :final VoteBreakdown voteBreakdown,
              ) =>
                voteBreakdown,
              _ => target.voteBreakdown,
            };
            final int abstain = (votes.total - votes.yes - votes.no).clamp(
              0,
              1 << 20,
            );
            final double progress = quorumNeeded > 0
                ? (votes.total / quorumNeeded).clamp(0.0, 1.0)
                : 0.0;
            final bool votingBusy = voteState is VoteProjectLoading;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (canVote) ...<Widget>[
                  Text(
                    phaseNumber != null && target is Phase
                        ? '${context.l10n.voteAsPillar(pillarInfo!.name)}'
                                  ', PHASE $phaseNumber'
                              .toUpperCase()
                        : context.l10n
                              .voteAsPillar(pillarInfo!.name)
                              .toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SyriusGradientButton(
                          key: const Key('accelerator_vote_yes_button'),
                          label: context.l10n.yes.capitalize(),
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          isLoading: votingBusy,
                          onPressed: votingBusy
                              ? null
                              : () => _castVote(
                                  context,
                                  AcceleratorProjectVote.yes,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SyriusPillButton(
                          key: const Key('accelerator_vote_no_button'),
                          label: context.l10n.no.capitalize(),
                          height: 36,
                          onPressed: votingBusy
                              ? null
                              : () => _castVote(
                                  context,
                                  AcceleratorProjectVote.no,
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SyriusGhostButton(
                        key: const Key('accelerator_vote_abstain_button'),
                        label: context.l10n.abstain,
                        onPressed: votingBusy
                            ? null
                            : () => _castVote(
                                context,
                                AcceleratorProjectVote.abstain,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _row(
                        tokens,
                        context.l10n.yes.capitalize(),
                        '${votes.yes}',
                      ),
                      const SizedBox(height: 8),
                      _row(tokens, context.l10n.no.capitalize(), '${votes.no}'),
                      const SizedBox(height: 8),
                      _row(tokens, context.l10n.abstain, '$abstain'),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: tokens.border),
                      const SizedBox(height: 12),
                      _row(
                        tokens,
                        context.l10n.quorum,
                        '${votes.total} of $quorumNeeded',
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: tokens.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tokens.znnGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.needsQuorumAndMoreYes(quorumNeeded),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _row(SyriusThemeTokens tokens, String label, String value) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: tokens.monoStyle(
            fontWeight: FontWeight.w500,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}
