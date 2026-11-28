import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Builds the Accelerator tab body from an [AcceleratorPillarState].
///
/// Renders [layoutBuilder] whenever resolution has populated — including when
/// `pillarInfo` is `null` (an ordinary account with no Pillar owner or
/// producer role) — so non-Pillar accounts are never stuck on the spinner.
@visibleForTesting
Widget buildAcceleratorTabBody(
  AcceleratorPillarState state,
  Widget Function(PillarInfo? pillarInfo, int? activePillarCount) layoutBuilder,
) {
  return switch (state) {
    AcceleratorPillarInitial() ||
    AcceleratorPillarLoading() => const SyriusLoadingWidget(),
    AcceleratorPillarFailure(:final SyriusException exception) =>
      SyriusErrorWidget(exception),
    AcceleratorPillarPopulated(
      :final PillarInfo? pillarInfo,
      :final int? activePillarCount,
    ) =>
      layoutBuilder(pillarInfo, activePillarCount),
  };
}

enum _AzSegment { voting, active, mine, all }

/// Redesigned Accelerator-Z tab matching mockup Screen 28.
class AcceleratorTabChild extends StatelessWidget {
  /// Creates an [AcceleratorTabChild].
  const AcceleratorTabChild({
    required this._onStepperNotificationSeeMorePressed,
    this._pillarBloc,
    this._balanceBloc,
    this._projectListBloc,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final AcceleratorPillarBloc? _pillarBloc;
  final AcceleratorBalanceBloc? _balanceBloc;
  final ProjectListBloc? _projectListBloc;

  @override
  Widget build(BuildContext context) {
    final AcceleratorPillarBloc? providedPillarBloc = _pillarBloc;
    final AcceleratorBalanceBloc? providedBalanceBloc = _balanceBloc;
    final ProjectListBloc? providedProjectListBloc = _projectListBloc;

    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        if (providedPillarBloc != null)
          BlocProvider<AcceleratorPillarBloc>.value(value: providedPillarBloc)
        else
          BlocProvider<AcceleratorPillarBloc>(
            create: (_) => AcceleratorPillarBloc(zenon: zenon!)
              ..add(
                AcceleratorPillarRequested(
                  address: Address.parse(kSelectedAddress!),
                ),
              ),
          ),
        if (providedBalanceBloc != null)
          BlocProvider<AcceleratorBalanceBloc>.value(value: providedBalanceBloc)
        else
          BlocProvider<AcceleratorBalanceBloc>(
            create: (_) =>
                AcceleratorBalanceBloc(zenon: zenon!)
                  ..add(const AcceleratorBalanceRequested()),
          ),
        if (providedProjectListBloc != null)
          BlocProvider<ProjectListBloc>.value(value: providedProjectListBloc)
        else
          BlocProvider<ProjectListBloc>(
            create: (_) => ProjectListBloc(zenon: zenon!),
          ),
      ],
      child: _View(
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
      ),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this._onStepperNotificationSeeMorePressed});

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  SelectedAddressNotifier? _addressNotifier;
  String? _lastSelectedAddress;
  late final TextEditingController _searchController;
  _AzSegment _segment = _AzSegment.all;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ProjectListBloc>().state.searchQuery,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SelectedAddressNotifier? notifier =
        Provider.of<SelectedAddressNotifier?>(context, listen: false);
    if (!identical(notifier, _addressNotifier)) {
      _addressNotifier?.removeListener(_onSelectedAddressChanged);
      _addressNotifier = notifier;
      _addressNotifier?.addListener(_onSelectedAddressChanged);
    }
    _lastSelectedAddress ??= kSelectedAddress;

    final ProjectListState projectState = context.read<ProjectListBloc>().state;
    if (_searchController.text != projectState.searchQuery) {
      _searchController.text = projectState.searchQuery;
    }

    final AcceleratorPillarState pillarState = context
        .read<AcceleratorPillarBloc>()
        .state;
    if (pillarState is AcceleratorPillarPopulated &&
        projectState.status == ProjectListStatus.initial) {
      context.read<ProjectListBloc>().add(
        ProjectListPillarUpdated(pillarInfo: pillarState.pillarInfo),
      );
    }
  }

  void _onSelectedAddressChanged() {
    final String? nextAddress = kSelectedAddress;
    if (nextAddress == null || nextAddress == _lastSelectedAddress) {
      return;
    }
    _lastSelectedAddress = nextAddress;
    if (mounted) {
      context.read<AcceleratorPillarBloc>().add(
        AcceleratorPillarRequested(address: Address.parse(nextAddress)),
      );
    }
  }

  @override
  void dispose() {
    _addressNotifier?.removeListener(_onSelectedAddressChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _refreshBalance() {
    if (mounted) {
      context.read<AcceleratorBalanceBloc>().add(
        const AcceleratorBalanceRequested(),
      );
    }
  }

  void _refreshAll() {
    if (!mounted) {
      return;
    }
    _searchController.clear();
    context.read<ProjectListBloc>().add(
      const ProjectListRequested(refresh: true, clearSearch: true),
    );
    _refreshBalance();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AcceleratorPillarBloc, AcceleratorPillarState>(
      listener: (BuildContext context, AcceleratorPillarState state) {
        if (state is AcceleratorPillarPopulated) {
          context.read<ProjectListBloc>().add(
            ProjectListPillarUpdated(pillarInfo: state.pillarInfo),
          );
        }
      },
      builder: (BuildContext context, AcceleratorPillarState state) {
        return buildAcceleratorTabBody(
          state,
          (PillarInfo? pillarInfo, int? activePillarCount) =>
              _buildWorkspace(context, pillarInfo, activePillarCount),
        );
      },
    );
  }

  Widget _buildWorkspace(
    BuildContext context,
    PillarInfo? pillarInfo,
    int? activePillarCount,
  ) {
    final SyriusThemeTokens tokens = context.syriusTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildTopSummaryBar(context, tokens, pillarInfo),
        const SizedBox(height: 16),
        Expanded(
          child: _buildProjectsCard(
            context,
            tokens,
            pillarInfo,
            activePillarCount,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSummaryBar(
    BuildContext context,
    SyriusThemeTokens tokens,
    PillarInfo? pillarInfo,
  ) {
    return SyriusCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: <Widget>[
          BlocBuilder<AcceleratorBalanceBloc, AcceleratorBalanceState>(
            builder: (_, AcceleratorBalanceState state) {
              String znnStr = '0';
              String qsrStr = '0';
              if (state is AcceleratorBalancePopulated) {
                znnStr = state.accountInfo
                    .getBalance(kZnnCoin.tokenStandard)
                    .addDecimals(coinDecimals);
                qsrStr = state.accountInfo
                    .getBalance(kQsrCoin.tokenStandard)
                    .addDecimals(coinDecimals);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    context.l10n.fund.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: tokens.monoStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: tokens.textPrimary,
                      ),
                      children: <InlineSpan>[
                        TextSpan(text: '$znnStr '),
                        TextSpan(
                          text: kZnnCoin.symbol,
                          style: tokens.monoStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.znnGreen,
                          ),
                        ),
                        TextSpan(
                          text: ' · $qsrStr ',
                          style: tokens.monoStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: tokens.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: kQsrCoin.symbol,
                          style: tokens.monoStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.qsrBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 34),
          BlocBuilder<ProjectListBloc, ProjectListState>(
            builder: (_, ProjectListState projectState) {
              final int votingCount = projectState.projects
                  .where(
                    (Project p) =>
                        p.status == AcceleratorProjectStatus.voting ||
                        (p.phases.isNotEmpty &&
                            p.phases.last.status ==
                                AcceleratorProjectStatus.voting),
                  )
                  .length;
              return SyriusMetricBlock(
                label: context.l10n.votingLabel,
                value: '$votingCount',
                valueSuffix: pillarInfo != null
                    ? context.l10n.needYourPillar
                    : context.l10n.projects.toLowerCase(),
              );
            },
          ),
          const Spacer(),
          SyriusPillButton(
            label: context.l10n.donate,
            icon: Icons.volunteer_activism_outlined,
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => StepperScreen(
                    breadcrumbParent: context.l10n.accelerator,
                    title: context.l10n.donate,
                    stepper: AcceleratorDonationStepperPage(
                      onDonationSubmitted: _refreshBalance,
                    ),
                    onStepperNotificationSeeMorePressed:
                        widget._onStepperNotificationSeeMorePressed,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          SyriusGradientButton(
            label: context.l10n.createProject,
            icon: Icons.add,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => StepperScreen(
                    breadcrumbParent: context.l10n.accelerator,
                    title: context.l10n.createProject,
                    stepper: CreateProjectStepperPage(
                      onProjectCreated: _refreshAll,
                    ),
                    onStepperNotificationSeeMorePressed:
                        widget._onStepperNotificationSeeMorePressed,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsCard(
    BuildContext context,
    SyriusThemeTokens tokens,
    PillarInfo? pillarInfo,
    int? activePillarCount,
  ) {
    return SyriusCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: <Widget>[
                SyriusSegmentedControl<_AzSegment>(
                  selected: _segment,
                  onChanged: (_AzSegment next) {
                    setState(() => _segment = next);
                  },
                  options: <SyriusSegmentOption<_AzSegment>>[
                    SyriusSegmentOption<_AzSegment>(
                      value: _AzSegment.voting,
                      label: context.l10n.votingLabel,
                    ),
                    SyriusSegmentOption<_AzSegment>(
                      value: _AzSegment.active,
                      label: context.l10n.active,
                    ),
                    SyriusSegmentOption<_AzSegment>(
                      value: _AzSegment.mine,
                      label: context.l10n.mine,
                    ),
                    SyriusSegmentOption<_AzSegment>(
                      value: _AzSegment.all,
                      label: context.l10n.all,
                    ),
                  ],
                ),
                if (pillarInfo != null) ...<Widget>[
                  const SizedBox(width: 10),
                  BlocBuilder<ProjectListBloc, ProjectListState>(
                    builder: (BuildContext context, ProjectListState state) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildPillarFilterPill(
                            context,
                            tokens,
                            label: context.l10n.needsVoting,
                            selected: state.selectedTags.contains(
                              AcceleratorProjectFilterTag.needsVoting,
                            ),
                            onTap: () => context.read<ProjectListBloc>().add(
                              const ProjectListFilterTagToggled(
                                tag: AcceleratorProjectFilterTag.needsVoting,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildPillarFilterPill(
                            context,
                            tokens,
                            label: context.l10n.alreadyVoted,
                            selected: state.selectedTags.contains(
                              AcceleratorProjectFilterTag.alreadyVoted,
                            ),
                            onTap: () => context.read<ProjectListBloc>().add(
                              const ProjectListFilterTagToggled(
                                tag: AcceleratorProjectFilterTag.alreadyVoted,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: 210,
                  child: SyriusSearchField(
                    controller: _searchController,
                    hintText: context.l10n.searchPlaceholder,
                    onChanged: (String value) {
                      context.read<ProjectListBloc>().add(
                        ProjectListSearchChanged(query: value),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SyriusPillButton(
                  label: _newestFirst
                      ? context.l10n.newest
                      : context.l10n.oldest,
                  icon: Icons.swap_vert,
                  compact: true,
                  onPressed: () {
                    setState(() => _newestFirst = !_newestFirst);
                    context.read<ProjectListBloc>().add(
                      const ProjectListSortToggled(),
                    );
                  },
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: context.l10n.refresh,
                  splashRadius: 16,
                  iconSize: 16,
                  color: tokens.textMuted,
                  onPressed: _refreshAll,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Text(
                    context.l10n.projects.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.l10n.budget.toUpperCase(),
                    textAlign: TextAlign.right,
                    style: tokens.microLabelStyle(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Text(
                    context.l10n.votes.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 90,
                  child: Text(
                    context.l10n.quorum.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                SizedBox(
                  width: 112,
                  child: Text(
                    context.l10n.status.toUpperCase(),
                    style: tokens.microLabelStyle(),
                  ),
                ),
                const SizedBox(width: 18),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Expanded(
            child: BlocBuilder<ProjectListBloc, ProjectListState>(
              builder: (BuildContext context, ProjectListState state) {
                return switch (state.status) {
                  ProjectListStatus.initial ||
                  ProjectListStatus.loading => const SyriusLoadingWidget(),
                  ProjectListStatus.failure => SyriusErrorWidget(
                    state.exception!,
                  ),
                  ProjectListStatus.populated => _buildProjectsList(
                    context,
                    tokens,
                    _filterBySegment(state.projects),
                    pillarInfo,
                    activePillarCount,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarFilterPill(
    BuildContext context,
    SyriusThemeTokens tokens, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? tokens.successSurface : tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? tokens.znnGreen.withValues(alpha: 0.45)
                : tokens.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? tokens.znnGreen : tokens.textSecondary,
          ),
        ),
      ),
    );
  }

  List<Project> _filterBySegment(List<Project> projects) {
    return switch (_segment) {
      _AzSegment.voting =>
        projects
            .where(
              (Project p) =>
                  p.status == AcceleratorProjectStatus.voting ||
                  (p.phases.isNotEmpty &&
                      p.phases.last.status == AcceleratorProjectStatus.voting),
            )
            .toList(),
      _AzSegment.active =>
        projects
            .where(
              (Project p) =>
                  p.status == AcceleratorProjectStatus.active ||
                  p.status == AcceleratorProjectStatus.paid,
            )
            .toList(),
      _AzSegment.mine =>
        projects
            .where(
              (Project p) =>
                  kDefaultAddressList.contains(p.owner.toString()) ||
                  p.owner.toString() == kSelectedAddress,
            )
            .toList(),
      _AzSegment.all => projects,
    };
  }

  Widget _buildProjectsList(
    BuildContext context,
    SyriusThemeTokens tokens,
    List<Project> projects,
    PillarInfo? pillarInfo,
    int? activePillarCount,
  ) {
    if (projects.isEmpty) {
      return SyriusEmptyState(message: context.l10n.noProjectsYet);
    }

    final int totalPillars = activePillarCount ?? kNumOfPillars ?? 0;
    final int quorumNeeded = totalPillars > 0
        ? (totalPillars * 33) ~/ 100 + 1
        : 33;

    return ListView.separated(
      itemCount: projects.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: tokens.border),
      itemBuilder: (BuildContext context, int index) {
        final Project project = projects[index];
        return _AcceleratorProjectRow(
          key: ValueKey<String>(project.id.toString()),
          project: project,
          pillarInfo: pillarInfo,
          quorumNeeded: quorumNeeded,
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => ProjectDetailsScreen(
                  pillarInfo: pillarInfo,
                  activePillarCount: activePillarCount,
                  project: project,
                  onStepperNotificationSeeMorePressed:
                      widget._onStepperNotificationSeeMorePressed,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AcceleratorProjectRow extends StatelessWidget {
  const _AcceleratorProjectRow({
    required this.project,
    required this.pillarInfo,
    required this.quorumNeeded,
    required this.onTap,
    super.key,
  });

  final Project project;
  final PillarInfo? pillarInfo;
  final int quorumNeeded;
  final VoidCallback onTap;

  String _relativeAge(int timestampSeconds) {
    final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int diff = (nowSec - timestampSeconds).clamp(0, 1 << 30);
    if (diff < 3600) {
      return '${(diff ~/ 60).clamp(1, 59)} m ago';
    }
    if (diff < 86400) {
      return '${diff ~/ 3600} h ago';
    }
    return '${diff ~/ 86400} d ago';
  }

  SyriusStatusBadge _statusBadge(BuildContext context) {
    final bool needsPillarVote =
        pillarInfo != null &&
        (project.status == AcceleratorProjectStatus.voting ||
            (project.phases.isNotEmpty &&
                project.phases.last.status == AcceleratorProjectStatus.voting));
    if (needsPillarVote) {
      return SyriusStatusBadge(
        label: context.l10n.yourVote,
        tone: SyriusBadgeTone.warning,
        icon: Icons.how_to_vote_outlined,
      );
    }
    return switch (project.status) {
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
      AcceleratorProjectStatus.paid => SyriusStatusBadge(
        label: context.l10n.paid,
        tone: SyriusBadgeTone.success,
        icon: Icons.check,
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

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final String ownerStr = project.owner.toString();
    final String ownerLabel =
        kAddressLabelMap[ownerStr] ?? project.owner.toShortString();
    final VoteBreakdown votes = project.voteBreakdown;
    final int abstain = (votes.total - votes.yes - votes.no).clamp(0, 1 << 20);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    project.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by $ownerLabel · '
                    '${_relativeAge(project.creationTimestamp)}',
                    overflow: TextOverflow.ellipsis,
                    style: tokens.monoStyle(
                      fontSize: 11.5,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${project.znnFundsNeeded.addDecimals(coinDecimals)} '
                    '${kZnnCoin.symbol}',
                    style: tokens.monoStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${project.qsrFundsNeeded.addDecimals(coinDecimals)} '
                    '${kQsrCoin.symbol}',
                    style: tokens.monoStyle(
                      fontSize: 12,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _VoteBreakdownBar(
                      yes: votes.yes,
                      no: votes.no,
                      abstain: abstain,
                      quorumNeeded: quorumNeeded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${votes.yes} · ${votes.no} · $abstain',
                    style: tokens.monoStyle(
                      fontSize: 11.5,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 90,
              child: Text(
                '${votes.total} of $quorumNeeded',
                style: tokens.monoStyle(
                  fontSize: 12.5,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 112,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _statusBadge(context),
              ),
            ),
            SizedBox(
              width: 18,
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: tokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteBreakdownBar extends StatelessWidget {
  const _VoteBreakdownBar({
    required this.yes,
    required this.no,
    required this.abstain,
    required this.quorumNeeded,
  });

  final int yes;
  final int no;
  final int abstain;
  final int quorumNeeded;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final int denom = (yes + no + abstain) > quorumNeeded
        ? (yes + no + abstain)
        : (quorumNeeded > 0 ? quorumNeeded : 1);
    final int remaining = (denom - yes - no - abstain).clamp(0, denom);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Row(
          children: <Widget>[
            if (yes > 0)
              Expanded(
                flex: yes,
                child: Container(color: tokens.znnGreen),
              ),
            if (no > 0)
              Expanded(
                flex: no,
                child: Container(color: tokens.error),
              ),
            if (abstain > 0)
              Expanded(
                flex: abstain,
                child: Container(color: tokens.textMuted),
              ),
            if (remaining > 0)
              Expanded(
                flex: remaining,
                child: Container(color: tokens.border),
              ),
          ],
        ),
      ),
    );
  }
}
