import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';

part 'wallet_connect_sessions_event.dart';
part 'wallet_connect_sessions_state.dart';

/// BLoC that observes active WalletConnect sessions and handles session
/// disconnection.
class WalletConnectSessionsBloc
    extends Bloc<WalletConnectSessionsEvent, WalletConnectSessionsState> {
  /// Creates a [WalletConnectSessionsBloc] bound to [_web3WalletService].
  WalletConnectSessionsBloc({
    required this._web3WalletService,
  }) : super(
         WalletConnectSessionsState(
           sessions: List<SessionData>.unmodifiable(
             _web3WalletService.sessions.value,
           ),
         ),
       ) {
    on<WalletConnectSessionsRefreshRequested>(_onRefreshRequested);
    on<WalletConnectSessionDisconnectRequested>(_onDisconnectRequested);
    on<_WalletConnectSessionsUpdated>(_onSessionsUpdated);

    _web3WalletService.sessions.addListener(_onSessionsChanged);
  }

  final IWeb3WalletService _web3WalletService;

  void _onSessionsChanged() {
    if (!isClosed) {
      add(
        _WalletConnectSessionsUpdated(
          List<SessionData>.unmodifiable(_web3WalletService.sessions.value),
        ),
      );
    }
  }

  void _onRefreshRequested(
    WalletConnectSessionsRefreshRequested event,
    Emitter<WalletConnectSessionsState> emit,
  ) {
    emit(
      state.copyWith(
        sessions: List<SessionData>.unmodifiable(
          _web3WalletService.sessions.value,
        ),
        clearError: true,
      ),
    );
  }

  void _onSessionsUpdated(
    _WalletConnectSessionsUpdated event,
    Emitter<WalletConnectSessionsState> emit,
  ) {
    emit(state.copyWith(sessions: event._sessions));
  }

  Future<void> _onDisconnectRequested(
    WalletConnectSessionDisconnectRequested event,
    Emitter<WalletConnectSessionsState> emit,
  ) async {
    if (state.disconnectingTopics.contains(event.topic)) {
      return;
    }

    emit(
      state.copyWith(
        disconnectingTopics: Set<String>.unmodifiable(
          <String>{...state.disconnectingTopics, event.topic},
        ),
        clearError: true,
      ),
    );

    try {
      await _web3WalletService.disconnectSession(topic: event.topic);
      final Set<String> remaining = Set<String>.from(state.disconnectingTopics)
        ..remove(event.topic);
      emit(
        state.copyWith(
          sessions: List<SessionData>.unmodifiable(
            _web3WalletService.sessions.value,
          ),
          disconnectingTopics: Set<String>.unmodifiable(remaining),
          clearError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      final Set<String> remaining = Set<String>.from(state.disconnectingTopics)
        ..remove(event.topic);
      emit(
        state.copyWith(
          disconnectingTopics: Set<String>.unmodifiable(remaining),
          error: error,
          errorCount: state.errorCount + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _web3WalletService.sessions.removeListener(_onSessionsChanged);
    return super.close();
  }
}
