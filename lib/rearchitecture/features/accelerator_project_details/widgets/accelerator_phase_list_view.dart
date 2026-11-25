import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays a searchable list of phases belonging to an Accelerator project.
class AcceleratorPhaseListView extends StatefulWidget {
  /// Creates an [AcceleratorPhaseListView].
  const AcceleratorPhaseListView({
    required this._pillarInfo,
    required this._phases,
    required this._project,
    required this._onStepperNotificationSeeMorePressed,
    this._activePillarCount,
    this._refreshGeneration = 0,
    this._onPhaseUpdated,
    super.key,
  });

  final PillarInfo? _pillarInfo;
  final List<Phase> _phases;
  final Project _project;
  final VoidCallback _onStepperNotificationSeeMorePressed;
  final int? _activePillarCount;
  final int _refreshGeneration;
  final VoidCallback? _onPhaseUpdated;

  @override
  State<AcceleratorPhaseListView> createState() =>
      _AcceleratorPhaseListViewState();
}

class _AcceleratorPhaseListViewState extends State<AcceleratorPhaseListView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchControllerChanged);
  }

  void _onSearchControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Phase> filteredPhases = _filterPhases(
      widget._phases,
      _searchController.text,
    );

    return Container(
      margin: const EdgeInsets.all(15),
      child: Column(
        children: <Widget>[
          _buildSearchInputField(context),
          const SizedBox(height: 10),
          Expanded(
            child: filteredPhases.isEmpty
                ? SyriusErrorWidget(context.l10n.noMatchingPhases)
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView.separated(
                      separatorBuilder: (BuildContext _, int _) =>
                          const SizedBox(height: 15),
                      controller: _scrollController,
                      itemCount: filteredPhases.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Phase phase = filteredPhases[index];
                        return AcceleratorProjectListItem(
                          key: ValueKey<String>(phase.id.toString()),
                          pillarInfo: widget._pillarInfo,
                          activePillarCount: widget._activePillarCount,
                          acceleratorProject: phase,
                          project: widget._project,
                          refreshGeneration: widget._refreshGeneration,
                          onPhaseUpdated: widget._onPhaseUpdated,
                          onStepperNotificationSeeMorePressed:
                              widget._onStepperNotificationSeeMorePressed,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInputField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: context.l10n.searchByIdNameDescriptionUrl,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ClearContentButton(controller: _searchController),
      ),
    );
  }

  List<Phase> _filterPhases(List<Phase> phases, String query) {
    final String lowerQuery = query.trim().toLowerCase();
    if (lowerQuery.isEmpty) {
      return phases;
    }
    return phases
        .where(
          (Phase phase) =>
              phase.id.toString().toLowerCase().contains(lowerQuery) ||
              phase.name.toLowerCase().contains(lowerQuery) ||
              phase.description.toLowerCase().contains(lowerQuery) ||
              phase.url.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchControllerChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
