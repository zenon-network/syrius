import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/logger.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ProjectListBloc with RefreshBlocMixin {
  List<Project>? _allProjects;

  final List<AccProjectsFilterTag> selectedProjectsFilterTag = [];

  final PillarInfo? pillarInfo;

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

  void refreshResults() {
    if (!_onSearchInputChangedSubject.isClosed) {
      onRefreshResultsRequest.add(null);
    }
  }

  Stream<InfiniteScrollBlocListingState<Project>> _doRefreshResults() async* {
    yield InfiniteScrollBlocListingState<Project>();
    yield* _fetchList(0);
  }

  static const _pageSize = 10;

  final _subscriptions = CompositeSubscription();

  final _onNewListingStateController =
      BehaviorSubject<InfiniteScrollBlocListingState<Project>>.seeded(
    InfiniteScrollBlocListingState<Project>(),
  );

  Stream<InfiniteScrollBlocListingState<Project>> get onNewListingState =>
      _onNewListingStateController.stream;

  final _onPageRequest = StreamController<int>();

  Sink<int> get onPageRequestSink => _onPageRequest.sink;

  final _onSearchInputChangedSubject = BehaviorSubject<String?>.seeded(null);

  Sink<String?> get onRefreshResultsRequest =>
      _onSearchInputChangedSubject.sink;

  List<Project>? get lastListingItems =>
      _onNewListingStateController.value.itemList;

  Sink<String?> get onSearchInputChangedSink =>
      _onSearchInputChangedSubject.sink;

  String? get _searchInputTerm => _onSearchInputChangedSubject.value;

  Stream<InfiniteScrollBlocListingState<Project>> _fetchList(
      int pageKey) async* {
    final lastListingState = _onNewListingStateController.value;
    try {
      final newItems = await getData(pageKey, _pageSize, _searchInputTerm);
      final isLastPage = newItems.length < _pageSize;
      final nextPageKey = isLastPage ? null : pageKey + 1;
      List<Project> allItems = [
        ...lastListingState.itemList ?? [],
        ...newItems
      ];
      yield InfiniteScrollBlocListingState<Project>(
        error: null,
        nextPageKey: nextPageKey,
        itemList: allItems,
      );
    } catch (e) {
      Logger.logError(e);
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
    List<Project> results = [];
    if (searchTerm != null && searchTerm.isNotEmpty) {
      results =
          _filterProjectsBySearchKeyWord(_allProjects!, searchTerm).toList();
    } else {
      results = _allProjects!;
    }
    results = (await _filterProjectsAccordingToPillarInfo(
        await _filterProjectsByTags(results)));
    return results.sublist(
      pageKey * pageSize,
      (pageKey + 1) * pageSize <= results.length
          ? (pageKey + 1) * pageSize
          : results.length,
    );
  }

  /*
  This method filters the projects according to the following rule:
  if a user doesn't have a Pillar, then we only show him the active
  projects
   */
  Future<List<Project>> _filterProjectsAccordingToPillarInfo(
      Set<Project> projectList) async {
    bool isPillarAddress = pillarInfo != null;
    if (isPillarAddress) {
      return projectList.toList();
    } else {
      List<Project> activeProjects = projectList
          .where(
            (project) =>
                project.status == AcceleratorProjectStatus.active ||
                project.owner.toString() == kSelectedAddress,
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
      List<Project> projects, String searchKeyWord) {
    var filteredProjects = <Project>{};
    filteredProjects.addAll(
      projects.where(
        (element) =>
            element.id.toString().toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    filteredProjects.addAll(
      projects.where(
        (element) =>
            element.owner.toString().toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    filteredProjects.addAll(
      projects.where(
        (element) =>
            element.name.toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    filteredProjects.addAll(
      projects.where(
        (element) =>
            element.description.toLowerCase().contains(
                  searchKeyWord.toLowerCase(),
                ) &&
            !filteredProjects.contains(element),
      ),
    );
    filteredProjects.addAll(
      projects.where(
        (element) =>
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
      Iterable<Project> filteredProjects = projects;
      if (selectedProjectsFilterTag.contains(AccProjectsFilterTag.myProjects)) {
        filteredProjects = filteredProjects.where(
          (project) => kDefaultAddressList.contains(project.owner.toString()),
        );
      }
      if (selectedProjectsFilterTag
          .contains(AccProjectsFilterTag.onlyAccepted)) {
        filteredProjects = filteredProjects.where(
            (project) => project.status == AcceleratorProjectStatus.active);
      }
      if (selectedProjectsFilterTag
          .contains(AccProjectsFilterTag.votingOpened)) {
        votedProjectIds ??= await _getVotedProjectIdsByPillar(filteredProjects);
        filteredProjects = filteredProjects.where(
          (project) =>
              project.status == AcceleratorProjectStatus.voting &&
              !votedProjectIds!.contains(project.id),
        );
      }
      if (selectedProjectsFilterTag
          .contains(AccProjectsFilterTag.alreadyVoted)) {
        votedProjectIds ??= await _getVotedProjectIdsByPillar(filteredProjects);
        filteredProjects = filteredProjects.where(
          (project) => votedProjectIds!.contains(project.id),
        );
      }
      return filteredProjects.toSet();
    } else {
      return projects.toSet();
    }
  }

  Future<Iterable<Hash>> _getVotedProjectIdsByPillar(
      Iterable<Project> projects) async {
    var pillarVotes = await zenon!.embedded.accelerator.getPillarVotes(
      pillarInfo!.name,
      projects.map((e) => e.id.toString()).toList(),
    );
    return pillarVotes.where((e) => e != null).map((e) => e!.id);
  }
}
