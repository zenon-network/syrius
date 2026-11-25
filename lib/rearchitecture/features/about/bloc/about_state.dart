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

/// State emitted once [stats] have been loaded from the connected node.
final class AboutPopulated extends AboutState {
  /// Creates an [AboutPopulated] state.
  const AboutPopulated({required this.stats});

  /// Loaded general node and process statistics.
  final GeneralStats stats;

  @override
  List<Object?> get props => <Object?>[stats];
}

/// State emitted when fetching component details fails.
final class AboutFailure extends AboutState {
  /// Creates an [AboutFailure] state.
  const AboutFailure({required this.exception});

  /// Mapped error describing the failure.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
