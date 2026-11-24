part of 'join_swap_availability_cubit.dart';

/// Base class for join-swap availability states.
sealed class JoinSwapAvailabilityState extends Equatable {
  /// Creates a [JoinSwapAvailabilityState].
  const JoinSwapAvailabilityState();

  @override
  List<Object?> get props => <Object?>[];
}

/// State emitted while the initial HTLC can still be joined safely.
final class JoinSwapAvailable extends JoinSwapAvailabilityState {
  /// Creates a [JoinSwapAvailable] state.
  const JoinSwapAvailable({required this.minutesLeftToJoin});

  /// Whole or partial minutes remaining before joining becomes unsafe.
  final int minutesLeftToJoin;

  @override
  List<Object?> get props => <Object?>[minutesLeftToJoin];
}

/// State emitted when the initial HTLC can no longer be joined safely.
final class JoinSwapUnavailable extends JoinSwapAvailabilityState {
  /// Creates a [JoinSwapUnavailable] state.
  const JoinSwapUnavailable();
}
