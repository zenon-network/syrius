import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'complete_swap_event.dart';

part 'complete_swap_state.dart';

/// Completes an HTLC swap by unlocking the counterparty deposit.
class CompleteSwapBloc extends Bloc<CompleteSwapEvent, CompleteSwapState> {
  /// Creates a [CompleteSwapBloc].
  CompleteSwapBloc({
    required this._htlcSwapUnlockService,
    required this._swapRepository,
    required this._zenonAddressUtils,
  }) : super(const CompleteSwapInitial()) {
    on<CompleteSwapRequested>(_onCompleteSwapRequested);
  }

  final HtlcSwapUnlockService _htlcSwapUnlockService;
  final P2pSwapRepository<HtlcSwap> _swapRepository;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onCompleteSwapRequested(
    CompleteSwapRequested event,
    Emitter<CompleteSwapState> emit,
  ) async {
    try {
      emit(const CompleteSwapLoading());

      final HtlcSwap swap = event.swap;
      final AccountBlockTemplate block = await _htlcSwapUnlockService.unlock(
        swap,
      );

      final HtlcSwap completedSwap = swap.copyWith(
        state: P2pSwapState.completed,
      );
      await _swapRepository.storeSwap(completedSwap);
      _zenonAddressUtils.refreshBalance();
      emit(CompleteSwapDone(block: block, swap: completedSwap));
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(CompleteSwapFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(sanitizeSwapErrorForLogging(error), stackTrace);
      emit(CompleteSwapFailure(exception: FailureException()));
    }
  }
}
