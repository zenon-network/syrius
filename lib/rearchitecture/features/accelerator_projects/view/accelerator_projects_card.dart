import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Card displaying the searchable, filterable list of Accelerator-Z projects.
class AcceleratorProjectsCard extends StatelessWidget {
  /// Creates an [AcceleratorProjectsCard].
  const AcceleratorProjectsCard({
    required this._onStepperNotificationSeeMorePressed,
    required this._pillarInfo,
    this._activePillarCount,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final PillarInfo? _pillarInfo;
  final int? _activePillarCount;

  @override
  Widget build(BuildContext context) {
    return _View(
      onStepperNotificationSeeMorePressed: _onStepperNotificationSeeMorePressed,
      pillarInfo: _pillarInfo,
      activePillarCount: _activePillarCount,
    );
  }
}

class _View extends StatefulWidget {
  const _View({
    required this._onStepperNotificationSeeMorePressed,
    required this._pillarInfo,
    this._activePillarCount,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final PillarInfo? _pillarInfo;
  final int? _activePillarCount;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ProjectListBloc>().state.searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocRefreshLoadingBuilder<ProjectListBloc, ProjectListState>(
      isLoading: (ProjectListState state) =>
          state.status == ProjectListStatus.loading,
      builder: (BuildContext context, ValueListenable<bool> isRefreshLoading) {
        return NewCardScaffold(
          data: _buildCardData(context),
          isRefreshLoading: isRefreshLoading,
          onRefreshPressed: () {
            _searchController.clear();
            context.read<ProjectListBloc>().add(
              const ProjectListRequested(refresh: true, clearSearch: true),
            );
          },
          body: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: <Widget>[
                _buildSearchInputField(context),
                kVerticalSpacing,
                BlocBuilder<ProjectListBloc, ProjectListState>(
                  builder: (BuildContext context, ProjectListState state) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: _buildProjectsFilterTags(
                            context,
                            state.selectedTags,
                          ),
                        ),
                        Tooltip(
                          message: context.l10n.sortByLastUpdate,
                          child: InkWell(
                            onTap: () {
                              context.read<ProjectListBloc>().add(
                                const ProjectListSortToggled(),
                              );
                            },
                            child: Icon(
                              Entypo.select_arrows,
                              size: 15,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                kVerticalSpacing,
                Expanded(
                  child: BlocBuilder<ProjectListBloc, ProjectListState>(
                    builder: (BuildContext context, ProjectListState state) {
                      return switch (state.status) {
                        ProjectListStatus.initial ||
                        ProjectListStatus.loading =>
                          const SyriusLoadingWidget(),
                        ProjectListStatus.failure => SyriusErrorWidget(
                          state.exception!,
                        ),
                        ProjectListStatus.populated => _buildPopulatedList(
                          context,
                          state.projects,
                        ),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  CardData _buildCardData(BuildContext context) => CardData(
    title: context.l10n.projectList,
    description: context.l10n.listContainsAllProjects,
  );

  Widget _buildSearchInputField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: context.l10n.searchByIdOwnerNameDescriptionUrl,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ClearContentButton(
          controller: _searchController,
          onClear: () {
            context.read<ProjectListBloc>().add(
              const ProjectListSearchChanged(query: ''),
            );
          },
        ),
      ),
      onChanged: (String value) {
        context.read<ProjectListBloc>().add(
          ProjectListSearchChanged(query: value),
        );
      },
    );
  }

  Widget _buildProjectsFilterTags(
    BuildContext context,
    Set<AcceleratorProjectFilterTag> selectedTags,
  ) {
    final List<Widget> children = <Widget>[];

    for (final AcceleratorProjectFilterTag tag
        in AcceleratorProjectFilterTag.values) {
      if (widget._pillarInfo == null &&
          (tag == AcceleratorProjectFilterTag.needsVoting ||
              tag == AcceleratorProjectFilterTag.alreadyVoted)) {
        continue;
      }
      children.add(
        _buildFilterChip(
          context,
          tag: tag,
          isSelected: selectedTags.contains(tag),
        ),
      );
    }

    return Wrap(spacing: 10, runSpacing: 6, children: children);
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required AcceleratorProjectFilterTag tag,
    required bool isSelected,
  }) {
    final String label = switch (tag) {
      AcceleratorProjectFilterTag.myProjects => context.l10n.myProjects,
      AcceleratorProjectFilterTag.onlyAccepted => context.l10n.onlyAccepted,
      AcceleratorProjectFilterTag.needsVoting => context.l10n.needsVoting,
      AcceleratorProjectFilterTag.alreadyVoted => context.l10n.alreadyVoted,
    };

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        context.read<ProjectListBloc>().add(
          ProjectListFilterTagToggled(tag: tag),
        );
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: 25,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: colorScheme.primaryContainer,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isSelected) ...<Widget>[
              Icon(
                Icons.check_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 15,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: kBodySmallTextStyle.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedList(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return SyriusErrorWidget(
        widget._pillarInfo == null && _searchController.text.isEmpty
            ? context.l10n.noActiveProjects
            : context.l10n.noProjectsFound,
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _scrollController,
        itemCount: projects.length,
        separatorBuilder: (BuildContext _, int _) => const SizedBox(height: 15),
        itemBuilder: (BuildContext context, int index) {
          final Project project = projects[index];
          return AcceleratorProjectListItem(
            key: ValueKey<String>(project.id.toString()),
            pillarInfo: widget._pillarInfo,
            activePillarCount: widget._activePillarCount,
            acceleratorProject: project,
            onStepperNotificationSeeMorePressed:
                widget._onStepperNotificationSeeMorePressed,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
