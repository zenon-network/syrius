part of 'fuse_plasma_bloc.dart';

/// Base class for all fuse plasma states.
sealed class FusePlasmaState extends Equatable {
  /// Creates a new [FusePlasmaState].
  const FusePlasmaState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before fusing starts.
final class FusePlasmaInitial extends FusePlasmaState {
  /// Creates a [FusePlasmaInitial] state.
  const FusePlasmaInitial();
}

/// Failure state emitted when fusing fails.
final class FusePlasmaFailure extends FusePlasmaState {
  /// Creates a [FusePlasmaFailure] state.
  const FusePlasmaFailure({required this.exception});

  /// The error that caused the fusing operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Success state emitted when fusing completes.
final class FusePlasmaDone extends FusePlasmaState {
  /// Creates a [FusePlasmaDone] state.
  const FusePlasmaDone({required this.accountBlock});

  /// Created account block.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object> get props => <Object>[accountBlock];
}

/// Loading state emitted while fusing is in progress.
final class FusePlasmaLoading extends FusePlasmaState {
  /// Creates a [FusePlasmaLoading] state.
  const FusePlasmaLoading();
}
