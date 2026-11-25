part of 'update_phase_bloc.dart';

/// Base state for [UpdatePhaseBloc].
sealed class UpdatePhaseState extends Equatable {
  /// Creates an [UpdatePhaseState].
  const UpdatePhaseState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before phase update starts.
final class UpdatePhaseInitial extends UpdatePhaseState {
  /// Creates an [UpdatePhaseInitial] state.
  const UpdatePhaseInitial();
}

/// State emitted while publishing the phase update account block.
final class UpdatePhaseLoading extends UpdatePhaseState {
  /// Creates an [UpdatePhaseLoading] state.
  const UpdatePhaseLoading();
}

/// State emitted after the phase update account block is published.
final class UpdatePhaseDone extends UpdatePhaseState {
  /// Creates an [UpdatePhaseDone] state.
  const UpdatePhaseDone({required this.accountBlock});

  /// Published account block for the phase update.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object?> get props => <Object?>[accountBlock];
}

/// State emitted when updating the phase fails.
final class UpdatePhaseFailure extends UpdatePhaseState {
  /// Creates an [UpdatePhaseFailure] state.
  const UpdatePhaseFailure({required this.exception});

  /// Failure describing why the phase update failed.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
