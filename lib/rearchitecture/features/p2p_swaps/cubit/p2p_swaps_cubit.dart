import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'p2p_swaps_state.dart';

/// A cubit that observes persisted P2P swaps.
class P2pSwapsCubit extends Cubit<P2pSwapsState> {
  /// Creates a [P2pSwapsCubit] and starts observing persisted swaps.
  P2pSwapsCubit({required this._swapRepository})
    : super(const P2pSwapsLoading()) {
    _watchSwaps();
  }

  final P2pSwapRepository<HtlcSwap> _swapRepository;

  StreamSubscription<List<HtlcSwap>>? _subscription;

  void _watchSwaps() {
    try {
      _subscription = _swapRepository.watchAllSwaps().listen(
        (List<HtlcSwap> swaps) => emit(P2pSwapsPopulated(swaps: swaps)),
        onError: _onError,
      );
    } on Object catch (error, stackTrace) {
      _onError(error, stackTrace);
    }
  }

  void _onError(Object error, StackTrace stackTrace) {
    addError(
      error is SyriusException ? error : sanitizeSwapErrorForLogging(error),
      stackTrace,
    );
    emit(P2pSwapsFailure(exception: _mapException(error)));
  }

  SyriusException _mapException(Object error) =>
      error is SyriusException ? error : FailureException();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
