part of 'peers_bloc.dart';

/// Column used to sort the connected peers table.
enum PeersSortColumn {
  /// Sort by peer IP address.
  ip,

  /// Sort by peer public key.
  publicKey,
}

/// Base class for [PeersBloc] events.
sealed class PeersEvent extends Equatable {
  /// Creates a [PeersEvent].
  const PeersEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests connected network peers from the node.
final class PeersRequested extends PeersEvent {
  /// Creates a [PeersRequested] event.
  const PeersRequested();
}

/// Toggles sorting of the currently loaded peer list by [column].
final class PeersSortToggled extends PeersEvent {
  /// Creates a [PeersSortToggled] event.
  const PeersSortToggled({required this.column});

  /// Column to sort by.
  final PeersSortColumn column;

  @override
  List<Object?> get props => <Object?>[column];
}
