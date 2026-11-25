import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'peers_event.dart';
part 'peers_state.dart';

/// Fetches and sorts the list of peers connected to the current Zenon node.
class PeersBloc extends Bloc<PeersEvent, PeersState> {
  /// Creates a [PeersBloc].
  PeersBloc({required this._zenon}) : super(const PeersInitial()) {
    on<PeersRequested>(_onPeersRequested);
    on<PeersSortToggled>(_onPeersSortToggled);
  }

  final Zenon _zenon;

  FutureOr<void> _onPeersRequested(
    PeersRequested event,
    Emitter<PeersState> emit,
  ) async {
    final PeersSortColumn? previousColumn = switch (state) {
      PeersPopulated(:final PeersSortColumn? sortColumn) => sortColumn,
      _ => null,
    };
    final bool previousAscending = switch (state) {
      PeersPopulated(:final bool sortAscending) => sortAscending,
      _ => true,
    };

    if (state is! PeersPopulated) {
      emit(const PeersLoading());
    }

    try {
      final NetworkInfo networkInfo = await _zenon.stats.networkInfo();
      final List<Peer> peers = List<Peer>.of(networkInfo.peers);
      if (previousColumn != null) {
        _sortPeers(peers, previousColumn, ascending: !previousAscending);
      }
      emit(
        PeersPopulated(
          peers: peers,
          sortColumn: previousColumn,
          sortAscending: previousAscending,
        ),
      );
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(PeersFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(PeersFailure(exception: FailureException()));
    }
  }

  void _onPeersSortToggled(PeersSortToggled event, Emitter<PeersState> emit) {
    final PeersState current = state;
    if (current is! PeersPopulated) {
      return;
    }

    final List<Peer> sorted = List<Peer>.of(current.peers);
    _sortPeers(sorted, event.column, ascending: current.sortAscending);

    emit(
      PeersPopulated(
        peers: sorted,
        sortColumn: event.column,
        sortAscending: !current.sortAscending,
      ),
    );
  }

  void _sortPeers(
    List<Peer> peers,
    PeersSortColumn column, {
    required bool ascending,
  }) {
    peers.sort((Peer a, Peer b) {
      final int comparison = switch (column) {
        PeersSortColumn.ip => a.ip.compareTo(b.ip),
        PeersSortColumn.publicKey => a.publicKey.compareTo(b.publicKey),
      };
      return ascending ? comparison : -comparison;
    });
  }
}
