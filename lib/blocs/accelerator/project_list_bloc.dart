import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ProjectListBloc with RefreshBlocMixin {

  ProjectListBloc({
    required this.pillarInfo,
  }) {
    _onPageRequest.stream
        .flatMap(_fetchList)
        .listen(_onNewListingStateController.add)
        .addTo(_subscriptions);

    _onSearchInputChangedSubject.stream
        .flatMap((_) => _doRefreshResults())
        .listen(_onNewListingStateController.add)
        .addTo(_subscriptions);

    listenToWsRestart(refreshResults);
  }
  List<Project>? _allProjects;

  final List<AccProjectsFilterTag> selectedProjectsFilterTag = <AccProjectsFilterTag>[];

  final PillarInfo? pillarInfo;

  void refreshResults() {
    if (!_onSearchInputChangedSubject.isClosed) {
      onRefreshResultsRequest.add(null);
    }
  }

  Stream<InfiniteScrollBlocListingState<Project>> _doRefreshResults() async* {
    yield InfiniteScrollBlocListingState<Project>();
    yield* _fetchList(0);
  }

  static const int _pageSize = 10;

  final CompositeSubscription _subscriptions = CompositeSubscription();

  final BehaviorSubject<InfiniteScrollBlocListingState<Project>> _onNewListingStateController =
      BehaviorSubject<InfiniteScrollBlocListingState<Project>>.seeded(
    InfiniteScrollBlocListingState<Project>(),
  );

  Stream<InfiniteScrollBlocListingState<Project>> get onNewListingState =>
      _onNewListingStateController.stream;

  final StreamController<int> _onPageRequest = StreamController<int>();

  Sink<int> get onPageRequestSink => _onPageRequest.sink;

  final BehaviorSubject<String?> _onSearchInputChangedSubject = BehaviorSubject<String?>.seeded(null);

  Sink<String?> get onRefreshResultsRequest =>
      _onSearchInputChangedSubject.sink;

  List<Project>? get lastListingItems =>
      _onNewListingStateController.value.itemList;

  Sink<String?> get onSearchInputChangedSink =>
      _onSearchInputChangedSubject.sink;

  String? get _searchInputTerm => _onSearchInputChangedSubject.value;

  Stream<InfiniteScrollBlocListingState<Project>> _fetchList(
      int pageKey,) async* {
    final InfiniteScrollBlocListingState<Project> lastListingState = _onNewListingStateController.value;
    try {
      final List<Project> newItems = await getData(pageKey, _pageSize, _searchInputTerm);
      final bool isLastPage = newItems.length < _pageSize;
      final int? nextPageKey = isLastPage ? null : pageKey + 1;
      final List<Project> allItems = <Project>[
        ...lastListingState.itemList ?? <Project>[],
        ...newItems,
      ];
      yield InfiniteScrollBlocListingState<Project>(
        nextPageKey: nextPageKey,
        itemList: allItems,
      );
    } catch (e, stackTrace) {
      Logger('ProjectListBloc').log(Level.WARNING, 'addError', e, stackTrace);
      yield InfiniteScrollBlocListingState<Project>(
        error: e,
        nextPageKey: lastListingState.nextPageKey,
        itemList: lastListingState.itemList,
      );
    }
  }

  void dispose() {
    _onSearchInputChangedSubject.close();
    _onNewListingStateController.close();
    _subscriptions.dispose();
    _onPageRequest.close();
  }

  Future<List<Project>> getData(
    int pageKey,
    int pageSize,
    String? searchTerm,
  ) async {
    _allProjects ??= (await zenon!.embedded.accelerator.getAll()).list;
    List<Project> results = <Project>[];
    if (searchTerm != null && searchTerm.isNotEmpty) {
      results =
          _filterProjectsBySearchKeyWord(_allProjects!, searchTerm).toList();
    } else {
      results = _allProjects!;
    }
    results = await _filterProjectsAccordingToPillarInfo(
        await _filterProjectsByTags(results),);
    return results.sublist(
      pageKey * pageSize,
      (pageKey + 1) * pageSize <= results.length
          ? (pageKey + 1) * pageSize
          : results.length,
    );
  }

  /*
  This method filters the projects according to the following rule:
  if a user doesn't have a Pillar, only show the active
  projects or all owned projects
   */
  Future<List<Project>> _filterProjectsAccordingToPillarInfo(
      Set<Project> projectList,) async {
    final bool isPillarAddress = pillarInfo != null;
    if (isPillarAddress) {
      return projectList.toList();
    } else {
      final List<Project> activeProjects = projectList
          .where(
            (Project project) =>
                project.status == AcceleratorProjectStatus.active ||
                kDefaultAddressList.contains(project.owner.toString()),
          )
          .toList();
      if (activeProjects.isNotEmpty) {
        return activeProjects;
      } else {
        throw 'No active projects';
      }
    }
  }

  Set<Project> _filterProjectsBySearchKeyWord(
      List<Project> projects, String searchKeyWord,) {
    final Set<Project> filteredProjects = <Project>{};
    filteredProjects.addAll(
      projects.where(
        (Project element) =>
            element.id.toString().toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    filteredProjects.addAll(
      projects.where(
        (Project element) =>
            element.owner.toString().toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    filteredProjects.addAll(
      projects.where(
        (Project element) =>
            element.name.toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    filteredProjects.addAll(
      projects.where(
        (Project element) =>
            element.description.toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    filteredProjects.addAll(
      projects.where(
        (Project element) =>
            element.url.toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    return filteredProjects;
  }

  Future<Set<Project>> _filterProjectsByTags(List<Project> projects) async {
    if (selectedProjectsFilterTag.isNotEmpty) {
      Iterable<Hash>? votedProjectIds;
      Iterable<Hash>? votedPhaseIds;
      Iterable<Project> filteredProjects = projects;
      if (selectedProjectsFilterTag.contains(AccProjectsFilterTag.myProjects)) {
        filteredProjects = filteredProjects.where(
          (Project project) => kDefaultAddressList.contains(project.owner.toString()),
        );
      }
      if (selectedProjectsFilterTag
          .contains(AccProjectsFilterTag.onlyAccepted)) {
        filteredProjects = filteredProjects.where(
            (Project project) => project.status == AcceleratorProjectStatus.active,);
      }
      if (selectedProjectsFilterTag
          .contains(AccProjectsFilterTag.needsVoting)) {
        votedProjectIds ??= await _getVotedProjectIdsByPillar(filteredProjects);
        votedPhaseIds ??= await _getVotedPhaseIdsByPillar(filteredProjects);
        filteredProjects = filteredProjects.where(
          (Project project) =>
              (project.status == AcceleratorProjectStatus.voting &&
                  !votedProjectIds!.contains(project.id)) ||
              project.phases.any((Phase phase) =>
                  phase.status == AcceleratorProjectStatus.voting &&
                  !votedPhaseIds!.contains(phase.id),),
        );
      }
      if (selectedProjectsFilterTag
          .contains(AccProjectsFilterTag.alreadyVoted)) {
        votedProjectIds ??= await _getVotedProjectIdsByPillar(filteredProjects);
        votedPhaseIds ??= await _getVotedPhaseIdsByPillar(filteredProjects);
        filteredProjects = filteredProjects.where(
          (Project project) =>
              (project.status == AcceleratorProjectStatus.voting &&
                  votedProjectIds!.contains(project.id)) ||
              project.phases.any((Phase phase) =>
                  phase.status == AcceleratorProjectStatus.voting &&
                  votedPhaseIds!.contains(phase.id),),
        );
      }
      return filteredProjects.toSet();
    } else {
      return projects.toSet();
    }
  }

  Future<Iterable<Hash>> _getVotedProjectIdsByPillar(
      Iterable<Project> projects,) async {
    final List<PillarVote?> pillarVotes = await zenon!.embedded.accelerator.getPillarVotes(
      pillarInfo!.name,
      projects.map((Project e) => e.id.toString()).toList(),
    );
    return pillarVotes.where((PillarVote? e) => e != null).map((PillarVote? e) => e!.id);
  }

  Future<Iterable<Hash>> _getVotedPhaseIdsByPillar(
      Iterable<Project> projects,) async {
    final List<PillarVote?> pillarVotes = await zenon!.embedded.accelerator.getPillarVotes(
      pillarInfo!.name,
      projects
          .expand((Project project) => project.phaseIds)
          .map((Hash id) => id.toString())
          .toList(),
    );
    return pillarVotes.where((PillarVote? e) => e != null).map((PillarVote? e) => e!.id);
  }
}
