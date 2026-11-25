part of 'create_project_bloc.dart';

/// Base state for [CreateProjectBloc].
sealed class CreateProjectState extends Equatable {
  /// Creates a [CreateProjectState].
  const CreateProjectState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before project creation starts.
final class CreateProjectInitial extends CreateProjectState {
  /// Creates a [CreateProjectInitial] state.
  const CreateProjectInitial();
}

/// State emitted while creating the project transaction.
final class CreateProjectLoading extends CreateProjectState {
  /// Creates a [CreateProjectLoading] state.
  const CreateProjectLoading();
}

/// State emitted once the project creation account block is published.
final class CreateProjectDone extends CreateProjectState {
  /// Creates a [CreateProjectDone] state.
  const CreateProjectDone({required this.accountBlock});

  /// Published project creation account block.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object?> get props => <Object?>[accountBlock];
}

/// State emitted when creating the project fails.
final class CreateProjectFailure extends CreateProjectState {
  /// Creates a [CreateProjectFailure] state.
  const CreateProjectFailure({required this.exception});

  /// Failure describing why the project could not be created.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
