part of 'peers_bloc.dart';

/// Base state for [PeersBloc].
sealed class PeersState extends Equatable {
  /// Creates a [PeersState].
  const PeersState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before peers have been loaded.
final class PeersInitial extends PeersState {
  /// Creates a [PeersInitial] state.
  const PeersInitial();
}

/// State emitted while peers are being fetched.
final class PeersLoading extends PeersState {
  /// Creates a [PeersLoading] state.
  const PeersLoading();
}

/// State emitted when peers have been fetched successfully.
final class PeersPopulated extends PeersState {
  /// Creates a [PeersPopulated] state.
  const PeersPopulated({
    required this.peers,
    this.sortColumn,
    this.sortAscending = true,
  });

  /// Connected peers ordered according to [sortColumn] and [sortAscending].
  final List<Peer> peers;

  /// Currently active sort column, if any.
  final PeersSortColumn? sortColumn;

  /// Whether the next sort toggle sorts ascending.
  final bool sortAscending;

  @override
  List<Object?> get props => <Object?>[peers, sortColumn, sortAscending];
}

/// State emitted when loading peers fails.
final class PeersFailure extends PeersState {
  /// Creates a [PeersFailure] state.
  const PeersFailure({required this.exception});

  /// The error that caused loading to fail.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
