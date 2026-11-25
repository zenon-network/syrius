part of 'create_phase_bloc.dart';

/// Base state for [CreatePhaseBloc].
sealed class CreatePhaseState extends Equatable {
  /// Creates a [CreatePhaseState].
  const CreatePhaseState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before phase creation starts.
final class CreatePhaseInitial extends CreatePhaseState {
  /// Creates a [CreatePhaseInitial] state.
  const CreatePhaseInitial();
}

/// State emitted while publishing the phase creation account block.
final class CreatePhaseLoading extends CreatePhaseState {
  /// Creates a [CreatePhaseLoading] state.
  const CreatePhaseLoading();
}

/// State emitted after the phase creation account block is published.
final class CreatePhaseDone extends CreatePhaseState {
  /// Creates a [CreatePhaseDone] state.
  const CreatePhaseDone({required this.accountBlock});

  /// Published account block for the new phase.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object?> get props => <Object?>[accountBlock];
}

/// State emitted when creating the phase fails.
final class CreatePhaseFailure extends CreatePhaseState {
  /// Creates a [CreatePhaseFailure] state.
  const CreatePhaseFailure({required this.exception});

  /// Failure describing why the phase could not be created.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
