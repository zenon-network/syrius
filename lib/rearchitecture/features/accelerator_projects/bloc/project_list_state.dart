part of 'project_list_bloc.dart';

/// Filter tags available on the Accelerator projects list.
enum AcceleratorProjectFilterTag {
  /// Projects owned by one of the wallet's addresses.
  myProjects,

  /// Projects currently in active (accepted) status.
  onlyAccepted,

  /// Projects or phases open for voting that the Pillar has not voted on yet.
  needsVoting,

  /// Projects or phases open for voting that the Pillar has already voted on.
  alreadyVoted,
}

/// Loading lifecycle for [ProjectListBloc].
enum ProjectListStatus {
  /// Before the initial project load completes.
  initial,

  /// While fetching or filtering projects.
  loading,

  /// Projects were loaded and filtered successfully.
  populated,

  /// Loading or filtering failed.
  failure,
}

/// State emitted by [ProjectListBloc].
final class ProjectListState extends Equatable {
  /// Creates a [ProjectListState].
  const ProjectListState({
    this.status = ProjectListStatus.initial,
    this.projects = const <Project>[],
    this.selectedTags = const <AcceleratorProjectFilterTag>{},
    this.searchQuery = '',
    this.sortAscending = true,
    this.pillarInfo,
    this.exception,
  });

  /// Current status of the project list.
  final ProjectListStatus status;

  /// Visible projects matching search, tags, Pillar visibility, and sorting.
  final List<Project> projects;

  /// Active filter tags.
  final Set<AcceleratorProjectFilterTag> selectedTags;

  /// Current search query.
  final String searchQuery;

  /// Whether sorting by `lastUpdateTimestamp` is ascending when triggered.
  final bool sortAscending;

  /// Pillar associated with the selected address, or `null` if none.
  final PillarInfo? pillarInfo;

  /// Error details when [status] is [ProjectListStatus.failure].
  final SyriusException? exception;

  /// Returns a copy with updated fields.
  ProjectListState copyWith({
    ProjectListStatus? status,
    List<Project>? projects,
    Set<AcceleratorProjectFilterTag>? selectedTags,
    String? searchQuery,
    bool? sortAscending,
    PillarInfo? pillarInfo,
    bool clearPillarInfo = false,
    SyriusException? exception,
    bool clearException = false,
  }) {
    return ProjectListState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      selectedTags: selectedTags ?? this.selectedTags,
      searchQuery: searchQuery ?? this.searchQuery,
      sortAscending: sortAscending ?? this.sortAscending,
      pillarInfo: clearPillarInfo ? null : (pillarInfo ?? this.pillarInfo),
      exception: clearException ? null : (exception ?? this.exception),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    projects,
    selectedTags,
    searchQuery,
    sortAscending,
    pillarInfo,
    exception,
  ];
}
