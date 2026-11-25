part of 'splash_bloc.dart';

/// Initialization mode executed by [SplashBloc].
enum SplashFlow {
  /// Standard application startup flow.
  normal,

  /// Wallet reset flow: stops services, wipes cache/HTLC/keystore, re-inits.
  resetWallet,

  /// Cache deletion flow: stops services, wipes cache boxes & Web3 cache,
  /// then exits.
  deleteCache,

  /// Fast development startup flow skipping default node check.
  development,
}

/// Base class for all splash initialization events.
sealed class SplashEvent extends Equatable {
  /// Creates a [SplashEvent].
  const SplashEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Starts the splash initialization or maintenance flow.
final class SplashStarted extends SplashEvent {
  /// Creates a [SplashStarted] event.
  const SplashStarted({required this.flow, required this.initApp});

  /// Which startup or maintenance flow to execute.
  final SplashFlow flow;

  /// Callback initializing theme, text scaling, preferences, and Hive boxes.
  final Future<void> Function() initApp;

  @override
  List<Object?> get props => <Object?>[flow];
}
