import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'start_p2p_swap_event.dart';

part 'start_p2p_swap_state.dart';

/// A bloc that creates and stores an outgoing HTLC swap.
class StartP2pSwapBloc extends Bloc<StartP2pSwapEvent, StartP2pSwapState> {
  /// Creates a [StartP2pSwapBloc].
  StartP2pSwapBloc({
    required this._accountBlockUtils,
    required this._swapRepository,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const StartP2pSwapInitial()) {
    on<StartP2pSwapRequested>(_onStartP2pSwapRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final P2pSwapRepository<HtlcSwap> _swapRepository;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onStartP2pSwapRequested(
    StartP2pSwapRequested event,
    Emitter<StartP2pSwapState> emit,
  ) async {
    try {
      emit(const StartP2pSwapLoading());

      final List<int> preimage = _generatePreimage();
      final Hash hashLock = await _getHashLock(event.hashType, preimage);
      final int expirationTime = await _getExpirationTime(
        event.initialHtlcDuration.inSeconds,
      );
      final AccountBlockTemplate transactionParams = _zenon.embedded.htlc
          .create(
            event.fromToken,
            event.fromAmount,
            event.counterpartyAddress,
            expirationTime,
            event.hashType,
            htlcPreimageMaxLength,
            hashLock.getBytes(),
          );

      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'start swap',
            address: event.selfAddress,
            waitForRequiredPlasma: true,
          );

      final HtlcSwap swap = HtlcSwap(
        id: response.hash.toString(),
        chainId: response.chainIdentifier,
        type: event.swapType,
        direction: P2pSwapDirection.outgoing,
        selfAddress: event.selfAddress.toString(),
        counterpartyAddress: event.counterpartyAddress.toString(),
        state: P2pSwapState.pending,
        startTime: DateTime.now().unixTimestamp,
        initialHtlcId: response.hash.toString(),
        initialHtlcExpirationTime: expirationTime,
        fromAmount: event.fromAmount,
        fromToken: event.fromToken,
        fromChain: event.fromChain,
        toChain: event.toChain,
        hashLock: hashLock.toString(),
        preimage: FormatUtils.encodeHexString(preimage),
        hashType: event.hashType,
      );

      await _swapRepository.storeSwap(swap);
      _zenonAddressUtils.refreshBalance();
      emit(StartP2pSwapDone(swap: swap));
    } on SyriusException catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(StartP2pSwapFailure(exception: error));
    } on Object catch (error, stackTrace) {
      addError(sanitizeSwapErrorForLogging(error), stackTrace);
      emit(StartP2pSwapFailure(exception: FailureException()));
    }
  }

  List<int> _generatePreimage() {
    const int maxInt = 256;
    final Random random = Random.secure();

    return List<int>.generate(
      htlcPreimageDefaultLength,
      (_) => random.nextInt(maxInt),
    );
  }

  Future<Hash> _getHashLock(int hashType, List<int> preimage) async {
    if (hashType == htlcHashTypeSha3) {
      return Hash.digest(preimage);
    } else if (hashType == htlcHashTypeSha256) {
      return Hash.fromBytes(await Crypto.sha256Bytes(preimage));
    }
    throw UnimplementedError('Hash type not implemented');
  }

  Future<int> _getExpirationTime(int duration) async {
    return (await _zenon.ledger.getFrontierMomentum()).timestamp + duration;
  }
}
