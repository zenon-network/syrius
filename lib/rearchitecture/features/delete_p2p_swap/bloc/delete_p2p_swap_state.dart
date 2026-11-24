part of 'delete_p2p_swap_bloc.dart';

/// Base class for all delete P2P swap states.
sealed class DeleteP2pSwapState extends Equatable {
  /// Creates a [DeleteP2pSwapState].
  const DeleteP2pSwapState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before deletion starts.
final class DeleteP2pSwapInitial extends DeleteP2pSwapState {
  /// Creates a [DeleteP2pSwapInitial].
  const DeleteP2pSwapInitial();
}

/// Loading state emitted while deletion is in progress.
final class DeleteP2pSwapLoading extends DeleteP2pSwapState {
  /// Creates a [DeleteP2pSwapLoading].
  const DeleteP2pSwapLoading();
}

/// Success state emitted when deletion completes.
final class DeleteP2pSwapDone extends DeleteP2pSwapState {
  /// Creates a [DeleteP2pSwapDone].
  const DeleteP2pSwapDone();
}

/// Failure state emitted when deletion fails.
final class DeleteP2pSwapFailure extends DeleteP2pSwapState {
  /// Creates a [DeleteP2pSwapFailure].
  const DeleteP2pSwapFailure({required this.exception});

  /// Error that caused the deletion operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}
