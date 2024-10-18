import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum AcceleratorProjectsFilterTag {
  myProjects,
  onlyAccepted,
  votingOpened,
}

class AcceleratorProjectList extends StatefulWidget {

  const AcceleratorProjectList(
    this.pillarInfo,
    this.acceleratorProjects, {
    required this.onStepperNotificationSeeMorePressed,
    this.projects,
    super.key,
  });
  final PillarInfo? pillarInfo;
  final List<AcceleratorProject> acceleratorProjects;
  final Project? projects;
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<AcceleratorProjectList> createState() => _AcceleratorProjectListState();
}

class _AcceleratorProjectListState extends State<AcceleratorProjectList> {
  final TextEditingController _searchKeyWordController =
      TextEditingController();

  final List<AcceleratorProjectsFilterTag> _selectedProjectsFilterTag = [];

  final ScrollController _scrollController = ScrollController();

  String _searchKeyWord = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      child: Column(
        children: [
          _getSearchInputField(),
          const SizedBox(
            height: 10,
          ),
          if (widget.acceleratorProjects.first is Project)
            _getProjectsFilterTags(),
          if (widget.acceleratorProjects.first is Project)
            const SizedBox(
              height: 10,
            ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.separated(
                separatorBuilder: (_, __) => const SizedBox(
                  height: 15,
                ),
                controller: _scrollController,
                shrinkWrap: true,
                itemCount:
                    _filterBaseProjects(widget.acceleratorProjects).length,
                itemBuilder: (context, index) => AcceleratorProjectListItem(
                  key: ValueKey(
                    _filterBaseProjects(widget.acceleratorProjects)
                        .elementAt(index)
                        .id
                        .toString(),
                  ),
                  pillarInfo: widget.pillarInfo,
                  acceleratorProject:
                      _filterBaseProjects(widget.acceleratorProjects)
                          .elementAt(index),
                  project: widget.projects,
                  onStepperNotificationSeeMorePressed:
                      widget.onStepperNotificationSeeMorePressed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSearchInputField() {
    return InputField(
      controller: _searchKeyWordController,
      hintText: 'Search by id, owner, name, description, or URL',
      suffixIcon: const Icon(
        Icons.search,
        color: Colors.green,
      ),
      onChanged: (value) {
        setState(() {
          _searchKeyWord = value;
        });
      },
    );
  }

  Set<AcceleratorProject> _filterBaseProjects(
      List<AcceleratorProject> acceleratorProjects,) {
    var filteredBaseProjects =
        _filterBaseProjectsBySearchKeyWord(acceleratorProjects);
    if (widget.acceleratorProjects.first is Project &&
        _selectedProjectsFilterTag.isNotEmpty) {
      filteredBaseProjects = _filterProjectsByFilterTags(
        filteredBaseProjects.map((e) => e as Project).toList(),
      );
    }
    return filteredBaseProjects;
  }

  Set<AcceleratorProject> _filterBaseProjectsBySearchKeyWord(
    List<AcceleratorProject> acceleratorProjects,
  ) {
    final filteredBaseProjects = <AcceleratorProject>{};
    filteredBaseProjects.addAll(
      acceleratorProjects.where(
        (element) => element.id.toString().toLowerCase().contains(
              _searchKeyWord.toLowerCase(),
            ),
      ),
    );
    if (acceleratorProjects.first is Project) {
      filteredBaseProjects.addAll(
        acceleratorProjects.where(
          (element) =>
              (element as Project).owner.toString().toLowerCase().contains(
                    _searchKeyWord.toLowerCase(),
                  ),
        ),
      );
    }
    filteredBaseProjects.addAll(
      acceleratorProjects.where(
        (element) => element.name.toLowerCase().contains(
              _searchKeyWord.toLowerCase(),
            ),
      ),
    );
    filteredBaseProjects.addAll(
      acceleratorProjects.where(
        (element) => element.description.toLowerCase().contains(
              _searchKeyWord.toLowerCase(),
            ),
      ),
    );
    filteredBaseProjects.addAll(
      acceleratorProjects.where(
        (element) => element.url.toLowerCase().contains(
              _searchKeyWord.toLowerCase(),
            ),
      ),
    );
    return filteredBaseProjects;
  }

  Widget _getProjectsFilterTags() {
    return Row(
      children: [
        _getProjectsFilterTag(AcceleratorProjectsFilterTag.myProjects),
        _getProjectsFilterTag(AcceleratorProjectsFilterTag.onlyAccepted),
        if (widget.pillarInfo != null)
          _getProjectsFilterTag(AcceleratorProjectsFilterTag.votingOpened),
      ],
    );
  }

  Widget _getProjectsFilterTag(AcceleratorProjectsFilterTag filterTag) {
    return TagWidget(
      text: FormatUtils.extractNameFromEnum<AcceleratorProjectsFilterTag>(
          filterTag,),
      hexColorCode: Theme.of(context)
          .colorScheme
          .primaryContainer
          .value
          .toRadixString(16)
          .substring(2),
      iconData: _selectedProjectsFilterTag.contains(filterTag)
          ? Icons.check_rounded
          : null,
      onPressed: () {
        setState(() {
          if (_selectedProjectsFilterTag.contains(filterTag)) {
            _selectedProjectsFilterTag.remove(filterTag);
          } else {
            _selectedProjectsFilterTag.add(filterTag);
          }
        });
      },
    );
  }

  Set<AcceleratorProject> _filterProjectsByFilterTags(List<Project> projects) {
    var filteredBaseProjects = const Iterable<Project>.empty();
    if (_selectedProjectsFilterTag
        .contains(AcceleratorProjectsFilterTag.myProjects)) {
      filteredBaseProjects = projects.where(
        (project) => project.owner.toString() == kSelectedAddress,
      );
    }
    if (_selectedProjectsFilterTag
        .contains(AcceleratorProjectsFilterTag.onlyAccepted)) {
      if (filteredBaseProjects.isNotEmpty) {
        filteredBaseProjects = filteredBaseProjects.where(
          (project) => project.status == AcceleratorProjectStatus.active,
        );
      } else {
        filteredBaseProjects = projects.where(
          (project) => project.status == AcceleratorProjectStatus.active,
        );
      }
    }
    if (_selectedProjectsFilterTag
        .contains(AcceleratorProjectsFilterTag.votingOpened)) {
      if (filteredBaseProjects.isNotEmpty) {
        filteredBaseProjects = filteredBaseProjects.where(
          (project) => project.status == AcceleratorProjectStatus.voting,
        );
      } else {
        filteredBaseProjects = projects.where(
          (project) => project.status == AcceleratorProjectStatus.voting,
        );
      }
    }
    return filteredBaseProjects.toSet();
  }

  @override
  void dispose() {
    _searchKeyWordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
