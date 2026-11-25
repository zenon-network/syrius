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
  PeersBloc({required this._zenon, Stream<bool>? wsRestartedStream})
    : super(const PeersInitial()) {
    on<PeersRequested>(_onPeersRequested);
    on<PeersSortToggled>(_onPeersSortToggled);
    _wsRestartSubscription = wsRestartedStream?.listen((bool restarted) {
      if (restarted && !isClosed) {
        add(const PeersRequested());
      }
    });
  }

  final Zenon _zenon;
  StreamSubscription<bool>? _wsRestartSubscription;

  FutureOr<void> _onPeersRequested(
    PeersRequested event,
    Emitter<PeersState> emit,
  ) async {
    if (state is! PeersPopulated) {
      emit(const PeersLoading());
    }

    try {
      final NetworkInfo networkInfo = await _zenon.stats.networkInfo();
      final PeersSortColumn? latestColumn = switch (state) {
        PeersPopulated(:final PeersSortColumn? sortColumn) => sortColumn,
        _ => null,
      };
      final bool latestAscending = switch (state) {
        PeersPopulated(:final bool sortAscending) => sortAscending,
        _ => true,
      };
      final List<Peer> peers = List<Peer>.of(networkInfo.peers);
      if (latestColumn != null) {
        _sortPeers(peers, latestColumn, ascending: !latestAscending);
      }
      emit(
        PeersPopulated(
          peers: peers,
          sortColumn: latestColumn,
          sortAscending: latestAscending,
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

  @override
  Future<void> close() async {
    await _wsRestartSubscription?.cancel();
    await super.close();
  }
}
