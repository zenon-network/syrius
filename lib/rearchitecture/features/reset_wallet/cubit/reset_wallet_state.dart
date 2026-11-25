part of 'reset_wallet_cubit.dart';

/// Base state for [ResetWalletCubit].
sealed class ResetWalletState extends Equatable {
  /// Creates a [ResetWalletState].
  const ResetWalletState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Idle state waiting for user confirmation.
final class ResetWalletInitial extends ResetWalletState {
  /// Creates a [ResetWalletInitial] state.
  const ResetWalletInitial();
}

/// State emitted while shutting down the embedded node prior to reset.
final class ResetWalletInProgress extends ResetWalletState {
  /// Creates a [ResetWalletInProgress] state.
  const ResetWalletInProgress();
}

/// State emitted when pre-reset cleanup finished and the app should launch
/// `SplashScreen` with `resetWalletFlow: true`.
final class ResetWalletReadyToNavigate extends ResetWalletState {
  /// Creates a [ResetWalletReadyToNavigate] state.
  const ResetWalletReadyToNavigate();
}
