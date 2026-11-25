import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/refresh_bloc_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'project_list_event.dart';
part 'project_list_state.dart';

/// Fetches, searches, filters, and sorts Accelerator-Z projects.
class ProjectListBloc extends Bloc<ProjectListEvent, ProjectListState>
    with RefreshBlocMixin {
  /// Creates a [ProjectListBloc].
  ProjectListBloc({
    required this._zenon,
    PillarInfo? pillarInfo,
    List<String> Function()? walletAddressesProvider,
    Duration debounceDuration = const Duration(milliseconds: 350),
    this._pageSize = rpcMaxPageSize,
    bool listenToWsReconnect = true,
  }) : _walletAddressesProvider =
           walletAddressesProvider ?? _defaultWalletAddresses,
       super(ProjectListState(pillarInfo: pillarInfo)) {
    on<ProjectListRequested>(
      _onProjectListRequested,
      transformer: restartable(),
    );
    on<ProjectListSearchChanged>(
      _onProjectListSearchChanged,
      transformer: _debounceRestartable(debounceDuration),
    );
    on<ProjectListFilterTagToggled>(
      _onProjectListFilterTagToggled,
      transformer: restartable(),
    );
    on<ProjectListSortToggled>(_onProjectListSortToggled);
    on<ProjectListPillarUpdated>(
      _onProjectListPillarUpdated,
      transformer: restartable(),
    );

    if (listenToWsReconnect) {
      listenToWsRestart(() {
        if (!isClosed) {
          add(const ProjectListRequested(refresh: true));
        }
      });
    }
  }

  final Zenon _zenon;
  final List<String> Function() _walletAddressesProvider;
  final int _pageSize;

  List<Project>? _allProjects;
  bool _cacheStale = false;
  bool _hasExplicitSort = false;
  int _requestGeneration = 0;

  static List<String> _defaultWalletAddresses() =>
      kDefaultAddressList.whereType<String>().toList();

  Future<void> _onProjectListRequested(
    ProjectListRequested event,
    Emitter<ProjectListState> emit,
  ) async {
    await _loadAndFilter(
      emit: emit,
      searchQuery: event.clearSearch ? '' : state.searchQuery,
      selectedTags: state.selectedTags,
      pillarInfo: state.pillarInfo,
      sortAscending: state.sortAscending,
      forceRefresh: event.refresh,
    );
  }

  Future<void> _onProjectListSearchChanged(
    ProjectListSearchChanged event,
    Emitter<ProjectListState> emit,
  ) async {
    await _loadAndFilter(
      emit: emit,
      searchQuery: event.query,
      selectedTags: state.selectedTags,
      pillarInfo: state.pillarInfo,
      sortAscending: state.sortAscending,
    );
  }

  Future<void> _onProjectListFilterTagToggled(
    ProjectListFilterTagToggled event,
    Emitter<ProjectListState> emit,
  ) async {
    final Set<AcceleratorProjectFilterTag> nextTags =
        Set<AcceleratorProjectFilterTag>.from(state.selectedTags);
    if (!nextTags.remove(event.tag)) {
      nextTags.add(event.tag);
    }

    await _loadAndFilter(
      emit: emit,
      searchQuery: state.searchQuery,
      selectedTags: nextTags,
      pillarInfo: state.pillarInfo,
      sortAscending: state.sortAscending,
    );
  }

  void _onProjectListSortToggled(
    ProjectListSortToggled event,
    Emitter<ProjectListState> emit,
  ) {
    if (state.status != ProjectListStatus.populated) {
      return;
    }

    final bool ascending = state.sortAscending;
    final List<Project> sorted = List<Project>.from(state.projects)
      ..sort(
        (Project a, Project b) => ascending
            ? a.lastUpdateTimestamp.compareTo(b.lastUpdateTimestamp)
            : b.lastUpdateTimestamp.compareTo(a.lastUpdateTimestamp),
      );
    _hasExplicitSort = true;

    emit(state.copyWith(projects: sorted, sortAscending: !ascending));
  }

  Future<void> _onProjectListPillarUpdated(
    ProjectListPillarUpdated event,
    Emitter<ProjectListState> emit,
  ) async {
    final Set<AcceleratorProjectFilterTag> nextTags =
        Set<AcceleratorProjectFilterTag>.from(state.selectedTags);
    if (event.pillarInfo == null) {
      nextTags
        ..remove(AcceleratorProjectFilterTag.needsVoting)
        ..remove(AcceleratorProjectFilterTag.alreadyVoted);
    }

    await _loadAndFilter(
      emit: emit,
      searchQuery: state.searchQuery,
      selectedTags: nextTags,
      pillarInfo: event.pillarInfo,
      sortAscending: state.sortAscending,
      forceRefresh: event.refresh,
    );
  }

  Future<void> _loadAndFilter({
    required Emitter<ProjectListState> emit,
    required String searchQuery,
    required Set<AcceleratorProjectFilterTag> selectedTags,
    required PillarInfo? pillarInfo,
    required bool sortAscending,
    bool forceRefresh = false,
  }) async {
    final int requestId = ++_requestGeneration;
    if (forceRefresh) {
      _cacheStale = true;
    }

    emit(
      state.copyWith(
        status: ProjectListStatus.loading,
        searchQuery: searchQuery,
        selectedTags: selectedTags,
        pillarInfo: pillarInfo,
        clearPillarInfo: pillarInfo == null,
        clearException: true,
      ),
    );

    try {
      final List<Project> allProjects;
      if (forceRefresh || _cacheStale || _allProjects == null) {
        final List<Project> fetched = await _fetchAllProjects();
        if (emit.isDone || requestId != _requestGeneration) return;
        _allProjects = fetched;
        _cacheStale = false;
        allProjects = fetched;
      } else {
        allProjects = _allProjects!;
      }

      final String trimmedQuery = searchQuery.trim();
      List<Project> results = trimmedQuery.isNotEmpty
          ? _filterBySearchKeyword(allProjects, trimmedQuery)
          : List<Project>.from(allProjects);

      results = await _filterByTags(
        results,
        selectedTags: selectedTags,
        pillarInfo: pillarInfo,
      );
      if (emit.isDone || requestId != _requestGeneration) return;

      results = _filterByPillarVisibility(results, pillarInfo: pillarInfo);

      if (_hasExplicitSort) {
        final bool appliedAscending = !sortAscending;
        results.sort(
          (Project a, Project b) => appliedAscending
              ? a.lastUpdateTimestamp.compareTo(b.lastUpdateTimestamp)
              : b.lastUpdateTimestamp.compareTo(a.lastUpdateTimestamp),
        );
      }

      emit(
        state.copyWith(
          status: ProjectListStatus.populated,
          projects: results,
          selectedTags: selectedTags,
          searchQuery: searchQuery,
          pillarInfo: pillarInfo,
          clearPillarInfo: pillarInfo == null,
          clearException: true,
        ),
      );
    } on SyriusException catch (e, stackTrace) {
      if (emit.isDone || requestId != _requestGeneration) return;
      addError(e, stackTrace);
      emit(state.copyWith(status: ProjectListStatus.failure, exception: e));
    } on Object catch (e, stackTrace) {
      if (emit.isDone || requestId != _requestGeneration) return;
      addError(e, stackTrace);
      emit(
        state.copyWith(
          status: ProjectListStatus.failure,
          exception: FailureException(),
        ),
      );
    }
  }

  Future<List<Project>> _fetchAllProjects() async {
    final List<Project> projects = <Project>[];
    int pageIndex = 0;

    while (true) {
      final ProjectList page = await _zenon.embedded.accelerator.getAll(
        pageIndex: pageIndex,
        pageSize: _pageSize,
      );
      projects.addAll(page.list);
      if (page.list.length < _pageSize) {
        break;
      }
      pageIndex += 1;
    }

    return projects;
  }

  List<Project> _filterByPillarVisibility(
    List<Project> projects, {
    required PillarInfo? pillarInfo,
  }) {
    if (pillarInfo != null) {
      return projects;
    }
    final List<String> walletAddresses = _walletAddressesProvider();
    return projects
        .where(
          (Project project) =>
              project.status == AcceleratorProjectStatus.active ||
              walletAddresses.contains(project.owner.toString()),
        )
        .toList();
  }

  List<Project> _filterBySearchKeyword(
    List<Project> projects,
    String searchKeyword,
  ) {
    final String lowerQuery = searchKeyword.toLowerCase();
    return projects
        .where(
          (Project project) =>
              project.id.toString().toLowerCase().contains(lowerQuery) ||
              project.owner.toString().toLowerCase().contains(lowerQuery) ||
              project.name.toLowerCase().contains(lowerQuery) ||
              project.description.toLowerCase().contains(lowerQuery) ||
              project.url.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  Future<List<Project>> _filterByTags(
    List<Project> projects, {
    required Set<AcceleratorProjectFilterTag> selectedTags,
    required PillarInfo? pillarInfo,
  }) async {
    if (selectedTags.isEmpty) {
      return projects;
    }

    final List<String> walletAddresses = _walletAddressesProvider();
    Iterable<Project> filtered = projects;

    if (selectedTags.contains(AcceleratorProjectFilterTag.myProjects)) {
      filtered = filtered.where(
        (Project project) => walletAddresses.contains(project.owner.toString()),
      );
    }
    if (selectedTags.contains(AcceleratorProjectFilterTag.onlyAccepted)) {
      filtered = filtered.where(
        (Project project) => project.status == AcceleratorProjectStatus.active,
      );
    }

    Set<Hash>? votedProjectIds;
    Set<Hash>? votedPhaseIds;
    final List<Project> snapshot = filtered.toList();

    if (pillarInfo != null &&
        selectedTags.contains(AcceleratorProjectFilterTag.needsVoting)) {
      votedProjectIds ??= await _getVotedProjectIdsByPillar(
        pillarInfo.name,
        snapshot,
      );
      votedPhaseIds ??= await _getVotedPhaseIdsByPillar(
        pillarInfo.name,
        snapshot,
      );
      filtered = snapshot.where(
        (Project project) =>
            (project.status == AcceleratorProjectStatus.voting &&
                !votedProjectIds!.contains(project.id)) ||
            project.phases.any(
              (Phase phase) =>
                  phase.status == AcceleratorProjectStatus.voting &&
                  !votedPhaseIds!.contains(phase.id),
            ),
      );
    }

    if (pillarInfo != null &&
        selectedTags.contains(AcceleratorProjectFilterTag.alreadyVoted)) {
      final List<Project> current = filtered.toList();
      votedProjectIds ??= await _getVotedProjectIdsByPillar(
        pillarInfo.name,
        current,
      );
      votedPhaseIds ??= await _getVotedPhaseIdsByPillar(
        pillarInfo.name,
        current,
      );
      filtered = current.where(
        (Project project) =>
            (project.status == AcceleratorProjectStatus.voting &&
                votedProjectIds!.contains(project.id)) ||
            project.phases.any(
              (Phase phase) =>
                  phase.status == AcceleratorProjectStatus.voting &&
                  votedPhaseIds!.contains(phase.id),
            ),
      );
    }

    return filtered.toList();
  }

  Future<Set<Hash>> _getVotedProjectIdsByPillar(
    String pillarName,
    Iterable<Project> projects,
  ) async {
    final List<String> ids = projects
        .map((Project project) => project.id.toString())
        .toList();
    if (ids.isEmpty) {
      return <Hash>{};
    }
    final List<PillarVote?> pillarVotes = await _zenon.embedded.accelerator
        .getPillarVotes(pillarName, ids);
    return pillarVotes
        .whereType<PillarVote>()
        .map((PillarVote vote) => vote.id)
        .toSet();
  }

  Future<Set<Hash>> _getVotedPhaseIdsByPillar(
    String pillarName,
    Iterable<Project> projects,
  ) async {
    final List<String> ids = projects
        .expand((Project project) => project.phaseIds)
        .map((Hash id) => id.toString())
        .toList();
    if (ids.isEmpty) {
      return <Hash>{};
    }
    final List<PillarVote?> pillarVotes = await _zenon.embedded.accelerator
        .getPillarVotes(pillarName, ids);
    return pillarVotes
        .whereType<PillarVote>()
        .map((PillarVote vote) => vote.id)
        .toSet();
  }

  @override
  Future<void> close() async {
    cancelStreamSubscription();
    await super.close();
  }
}

EventTransformer<E> _debounceRestartable<E>(Duration duration) {
  return (Stream<E> events, EventMapper<E> mapper) {
    return restartable<E>().call(events.debounce(duration), mapper);
  };
}
