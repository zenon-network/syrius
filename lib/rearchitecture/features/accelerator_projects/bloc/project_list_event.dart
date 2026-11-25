part of 'project_list_bloc.dart';

/// Base event for [ProjectListBloc].
sealed class ProjectListEvent extends Equatable {
  /// Creates a [ProjectListEvent].
  const ProjectListEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests loading Accelerator projects, optionally forcing an RPC refresh.
final class ProjectListRequested extends ProjectListEvent {
  /// Creates a [ProjectListRequested] event.
  const ProjectListRequested({this.refresh = false, this.clearSearch = false});

  /// Whether to discard cached projects and re-fetch from the node.
  final bool refresh;

  /// Whether to also clear any active search query.
  final bool clearSearch;

  @override
  List<Object?> get props => <Object?>[refresh, clearSearch];
}

/// Updates the search query used to filter Accelerator projects.
final class ProjectListSearchChanged extends ProjectListEvent {
  /// Creates a [ProjectListSearchChanged] event.
  const ProjectListSearchChanged({required this.query});

  /// Raw search input entered by the user.
  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

/// Toggles an [AcceleratorProjectFilterTag] on or off.
final class ProjectListFilterTagToggled extends ProjectListEvent {
  /// Creates a [ProjectListFilterTagToggled] event.
  const ProjectListFilterTagToggled({required this.tag});

  /// Filter tag to toggle.
  final AcceleratorProjectFilterTag tag;

  @override
  List<Object?> get props => <Object?>[tag];
}

/// Toggles ascending vs descending sort order by last update timestamp.
final class ProjectListSortToggled extends ProjectListEvent {
  /// Creates a [ProjectListSortToggled] event.
  const ProjectListSortToggled();
}

/// Updates the resolved Pillar associated with the selected address.
final class ProjectListPillarUpdated extends ProjectListEvent {
  /// Creates a [ProjectListPillarUpdated] event.
  const ProjectListPillarUpdated({
    required this.pillarInfo,
    this.refresh = false,
  });

  /// Resolved Pillar for the active address, or `null` if none.
  final PillarInfo? pillarInfo;

  /// Whether to refresh the cached project list from the node.
  final bool refresh;

  @override
  List<Object?> get props => <Object?>[pillarInfo, refresh];
}
