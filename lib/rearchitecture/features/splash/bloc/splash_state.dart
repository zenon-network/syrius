part of 'splash_bloc.dart';

/// Destination screen selected after splash initialization completes.
enum SplashDestination {
  /// Onboarding wallet access screen when no wallet exists.
  accessWallet,

  /// Main wallet shell when a wallet and default node are configured.
  home,

  /// Node management screen when a wallet exists without a selected node.
  nodeManagement,
}

/// Base class for all splash states.
sealed class SplashState extends Equatable {
  /// Creates a [SplashState].
  const SplashState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before splash initialization starts.
final class SplashInitial extends SplashState {
  /// Creates a [SplashInitial].
  const SplashInitial();
}

/// State emitted while initialization, cache deletion, or wallet reset runs.
final class SplashInProgress extends SplashState {
  /// Creates a [SplashInProgress].
  const SplashInProgress();
}

/// State emitted when initialization finishes and navigation should occur.
final class SplashNavigateTo extends SplashState {
  /// Creates a [SplashNavigateTo] state.
  const SplashNavigateTo(this.destination);

  /// Target screen to replace the splash screen with.
  final SplashDestination destination;

  @override
  List<Object?> get props => <Object?>[destination];
}

/// State emitted after cache deletion completes and before the process exits.
final class SplashCacheDeleted extends SplashState {
  /// Creates a [SplashCacheDeleted].
  const SplashCacheDeleted();
}

/// State emitted when splash initialization or reset fails.
final class SplashFailure extends SplashState {
  /// Creates a [SplashFailure] state.
  const SplashFailure(this.error);

  /// Error encountered during startup or cleanup.
  final Object error;

  @override
  List<Object?> get props => <Object?>[error];
}
