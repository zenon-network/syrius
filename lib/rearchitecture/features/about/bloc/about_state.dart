part of 'about_bloc.dart';

/// Base state for [AboutBloc].
sealed class AboutState extends Equatable {
  const AboutState();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Initial state before component details have been requested.
final class AboutInitial extends AboutState {
  /// Creates an [AboutInitial] state.
  const AboutInitial();
}

/// State emitted while fetching node component details.
final class AboutLoading extends AboutState {
  /// Creates an [AboutLoading] state.
  const AboutLoading();
}

/// State emitted once at least one node diagnostic section has loaded.
///
/// When one or more individual node RPCs fail, [nodeError] contains the mapped
/// exception while unavailable fields in [nodeInfo] remain `null`.
final class AboutPopulated extends AboutState {
  /// Creates an [AboutPopulated] state.
  const AboutPopulated({required this.nodeInfo, this.nodeError});

  /// Loaded node diagnostic information (with `null` fields for failed RPCs).
  final AboutNodeInfo nodeInfo;

  /// Optional error from partial node RPC failures.
  final SyriusException? nodeError;

  @override
  List<Object?> get props => <Object?>[nodeInfo, nodeError];
}

/// State emitted when all node diagnostic RPCs fail.
final class AboutFailure extends AboutState {
  /// Creates an [AboutFailure] state.
  const AboutFailure({required this.exception});

  /// Mapped error describing the failure.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
