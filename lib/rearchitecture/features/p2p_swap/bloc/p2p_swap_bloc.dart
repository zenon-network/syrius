import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/p2p_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'p2p_swap_event.dart';

part 'p2p_swap_state.dart';

/// A bloc that periodically fetches one persisted HTLC swap by id.
class P2pSwapBloc extends Bloc<P2pSwapEvent, P2pSwapBlocState> {
  /// Creates a [P2pSwapBloc].
  P2pSwapBloc({
    required this._swapRepository,
    required this._swapId,
    this.refreshInterval = const Duration(seconds: 5),
  }) : super(const P2pSwapInitial()) {
    on<P2pSwapRequested>(_onSwapRequested);
    on<_P2pSwapRefreshRequested>(_onSwapRequested);
  }

  final P2pSwapRepository<HtlcSwap> _swapRepository;
  final String _swapId;

  /// The interval at which swap details are refreshed.
  final Duration refreshInterval;

  Timer? _autoRefresher;

  Future<void> _onSwapRequested(
    P2pSwapEvent event,
    Emitter<P2pSwapBlocState> emit,
  ) async {
    try {
      if (state is! P2pSwapPopulated) {
        emit(const P2pSwapLoading());
      }

      emit(P2pSwapPopulated(swap: await _getSwap()));
    } on SyriusException catch (e, stackTrace) {
      emit(P2pSwapFailure(exception: e));
      addError(e, stackTrace);
    } on Object catch (e, stackTrace) {
      emit(P2pSwapFailure(exception: FailureException()));
      addError(sanitizeSwapErrorForLogging(e), stackTrace);
    } finally {
      _scheduleRefresh();
    }
  }

  Future<HtlcSwap> _getSwap() async {
    final HtlcSwap? swap = await _swapRepository.getSwapById(_swapId);
    if (swap == null) {
      throw LocalizedSyriusException(SyriusErrorCode.swapDoesNotExist);
    }

    return swap;
  }

  void _scheduleRefresh() {
    if (isClosed || (_autoRefresher?.isActive ?? false)) {
      return;
    }

    _autoRefresher = Timer(refreshInterval, () {
      if (!isClosed) {
        add(const _P2pSwapRefreshRequested());
      }
    });
  }

  @override
  Future<void> close() {
    _autoRefresher?.cancel();
    return super.close();
  }
}
