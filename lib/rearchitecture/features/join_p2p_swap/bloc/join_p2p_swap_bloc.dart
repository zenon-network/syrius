import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'join_p2p_swap_event.dart';

part 'join_p2p_swap_state.dart';

/// A bloc that creates and stores an incoming HTLC swap.
class JoinP2pSwapBloc extends Bloc<JoinP2pSwapEvent, JoinP2pSwapState> {
  /// Creates a [JoinP2pSwapBloc].
  JoinP2pSwapBloc({
    required this._accountBlockUtils,
    required this._swapRepository,
    required this._zenon,
    required this._zenonAddressUtils,
    int Function()? unixTimeProvider,
  }) : _unixTimeProvider = unixTimeProvider ?? _currentUnixTime,
       super(const JoinP2pSwapInitial()) {
    on<JoinP2pSwapRequested>(_onJoinP2pSwapRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final P2pSwapRepository<HtlcSwap> _swapRepository;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;
  final int Function() _unixTimeProvider;

  static int _currentUnixTime() => DateTime.now().unixTimestamp;

  FutureOr<void> _onJoinP2pSwapRequested(
    JoinP2pSwapRequested event,
    Emitter<JoinP2pSwapState> emit,
  ) async {
    try {
      final int now = _unixTimeProvider();
      if (!event.initialHtlc.canBeSafelyJoinedAt(now)) {
        throw LocalizedSyriusException(
          SyriusErrorCode.depositExpiresTooSoonForSafeSwap,
        );
      }
      final int counterHtlcExpirationTime =
          now + kCounterHtlcDuration.inSeconds;

      emit(const JoinP2pSwapLoading());

      final AccountBlockTemplate transactionParams = _zenon.embedded.htlc
          .create(
            event.fromToken,
            event.fromAmount,
            event.initialHtlc.timeLocked,
            counterHtlcExpirationTime,
            event.initialHtlc.hashType,
            event.initialHtlc.keyMaxSize,
            event.initialHtlc.hashLock,
          );
      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'join swap',
            address: event.initialHtlc.hashLocked,
            waitForRequiredPlasma: true,
          );
      final HtlcSwap swap = HtlcSwap(
        id: event.initialHtlc.id.toString(),
        chainId: response.chainIdentifier,
        type: event.swapType,
        direction: P2pSwapDirection.incoming,
        selfAddress: event.initialHtlc.hashLocked.toString(),
        counterHtlcId: response.hash.toString(),
        counterHtlcExpirationTime: counterHtlcExpirationTime,
        counterpartyAddress: event.initialHtlc.timeLocked.toString(),
        state: P2pSwapState.active,
        startTime: now,
        initialHtlcId: event.initialHtlc.id.toString(),
        initialHtlcExpirationTime: event.initialHtlc.expirationTime,
        fromAmount: event.fromAmount,
        fromToken: event.fromToken,
        fromChain: event.fromChain,
        toAmount: event.initialHtlc.amount,
        toToken: event.toToken,
        toChain: event.toChain,
        hashLock: FormatUtils.encodeHexString(event.initialHtlc.hashLock),
        hashType: event.initialHtlc.hashType,
      );

      await _swapRepository.storeSwap(swap);
      _zenonAddressUtils.refreshBalance();
      emit(JoinP2pSwapDone(swap: swap));
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(JoinP2pSwapFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(sanitizeSwapErrorForLogging(error), stackTrace);
      emit(JoinP2pSwapFailure(exception: FailureException()));
    }
  }
}
