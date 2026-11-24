import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/p2p_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'delete_p2p_swap_event.dart';

part 'delete_p2p_swap_state.dart';

/// Deletes a persisted P2P swap.
class DeleteP2pSwapBloc extends Bloc<DeleteP2pSwapEvent, DeleteP2pSwapState> {
  /// Creates a [DeleteP2pSwapBloc].
  DeleteP2pSwapBloc({required this._swapRepository})
    : super(const DeleteP2pSwapInitial()) {
    on<DeleteP2pSwapRequested>(_onDeleteP2pSwapRequested);
  }

  final P2pSwapRepository<HtlcSwap> _swapRepository;

  FutureOr<void> _onDeleteP2pSwapRequested(
    DeleteP2pSwapRequested event,
    Emitter<DeleteP2pSwapState> emit,
  ) async {
    try {
      emit(const DeleteP2pSwapLoading());
      await _swapRepository.deleteSwap(event.swapId);
      emit(const DeleteP2pSwapDone());
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(DeleteP2pSwapFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(sanitizeSwapErrorForLogging(error), stackTrace);
      emit(DeleteP2pSwapFailure(exception: FailureException()));
    }
  }
}
