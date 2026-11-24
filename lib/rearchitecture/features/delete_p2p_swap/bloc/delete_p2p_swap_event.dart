part of 'delete_p2p_swap_bloc.dart';

/// Base class for all delete P2P swap events.
sealed class DeleteP2pSwapEvent extends Equatable {
  /// Creates a [DeleteP2pSwapEvent].
  const DeleteP2pSwapEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests deletion of a persisted P2P swap.
final class DeleteP2pSwapRequested extends DeleteP2pSwapEvent {
  /// Creates a [DeleteP2pSwapRequested].
  const DeleteP2pSwapRequested({required this.swapId});

  /// Identifier of the swap that should be deleted.
  final String swapId;

  @override
  List<Object> get props => <Object>[swapId];
}
