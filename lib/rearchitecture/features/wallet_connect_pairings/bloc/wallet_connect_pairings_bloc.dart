import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';

part 'wallet_connect_pairings_event.dart';
part 'wallet_connect_pairings_state.dart';

/// BLoC that observes WalletConnect pairings and handles pairing deactivation.
class WalletConnectPairingsBloc
    extends Bloc<WalletConnectPairingsEvent, WalletConnectPairingsState> {
  /// Creates a [WalletConnectPairingsBloc] bound to [_web3WalletService].
  WalletConnectPairingsBloc({
    required this._web3WalletService,
  }) : super(
         WalletConnectPairingsState(
           pairings: List<PairingInfo>.unmodifiable(
             _web3WalletService.pairings.value,
           ),
         ),
       ) {
    on<WalletConnectPairingsRefreshRequested>(_onRefreshRequested);
    on<WalletConnectPairingDeactivateRequested>(_onDeactivateRequested);
    on<_WalletConnectPairingsUpdated>(_onPairingsUpdated);

    _web3WalletService.pairings.addListener(_onPairingsChanged);
  }

  final IWeb3WalletService _web3WalletService;

  void _onPairingsChanged() {
    if (!isClosed) {
      add(
        _WalletConnectPairingsUpdated(
          List<PairingInfo>.unmodifiable(_web3WalletService.pairings.value),
        ),
      );
    }
  }

  void _onRefreshRequested(
    WalletConnectPairingsRefreshRequested event,
    Emitter<WalletConnectPairingsState> emit,
  ) {
    emit(
      state.copyWith(
        pairings: List<PairingInfo>.unmodifiable(
          _web3WalletService.pairings.value,
        ),
        clearError: true,
      ),
    );
  }

  void _onPairingsUpdated(
    _WalletConnectPairingsUpdated event,
    Emitter<WalletConnectPairingsState> emit,
  ) {
    emit(state.copyWith(pairings: event._pairings));
  }

  Future<void> _onDeactivateRequested(
    WalletConnectPairingDeactivateRequested event,
    Emitter<WalletConnectPairingsState> emit,
  ) async {
    if (state.deactivatingTopics.contains(event.topic)) {
      return;
    }

    emit(
      state.copyWith(
        deactivatingTopics: Set<String>.unmodifiable(
          <String>{...state.deactivatingTopics, event.topic},
        ),
        clearError: true,
      ),
    );

    try {
      await _web3WalletService.deactivatePairing(topic: event.topic);
      final Set<String> remaining = Set<String>.from(state.deactivatingTopics)
        ..remove(event.topic);
      emit(
        state.copyWith(
          pairings: List<PairingInfo>.unmodifiable(
            _web3WalletService.pairings.value,
          ),
          deactivatingTopics: Set<String>.unmodifiable(remaining),
          clearError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      final Set<String> remaining = Set<String>.from(state.deactivatingTopics)
        ..remove(event.topic);
      emit(
        state.copyWith(
          deactivatingTopics: Set<String>.unmodifiable(remaining),
          error: error,
          errorCount: state.errorCount + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _web3WalletService.pairings.removeListener(_onPairingsChanged);
    return super.close();
  }
}
