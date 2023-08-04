import 'dart:math';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/htlc_swap.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StartHtlcSwapBloc extends BaseBloc<HtlcSwap?> {
  void startHtlcSwap({
    required Address selfAddress,
    required Address counterpartyAddress,
    required Token fromToken,
    required BigInt fromAmount,
    required int hashType,
    required P2pSwapType swapType,
    required P2pSwapChain fromChain,
    required P2pSwapChain toChain,
    required int initialHtlcDuration,
  }) async {
    try {
      addEvent(null);
      final preimage = _generatePreimage();
      final hashLock = await _getHashLock(hashType, preimage);
      final expirationTime = await _getExpirationTime(initialHtlcDuration);
      AccountBlockTemplate transactionParams = zenon!.embedded.htlc.create(
        fromToken,
        fromAmount,
        counterpartyAddress,
        expirationTime,
        hashType,
        htlcPreimageMaxLength,
        hashLock.getBytes(),
      );
      KeyPair blockSigningKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(selfAddress.toString()),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'start swap',
              blockSigningKey: blockSigningKeyPair, waitForRequiredPlasma: true)
          .then(
        (response) async {
          final swap = HtlcSwap(
            id: response.hash.toString(),
            chainId: response.chainIdentifier,
            type: swapType,
            direction: P2pSwapDirection.outgoing,
            selfAddress: selfAddress.toString(),
            counterpartyAddress: counterpartyAddress.toString(),
            state: P2pSwapState.pending,
            startTime: DateTimeUtils.unixTimeNow,
            initialHtlcId: response.hash.toString(),
            initialHtlcExpirationTime: expirationTime,
            fromAmount: fromAmount,
            fromTokenStandard: fromToken.tokenStandard.toString(),
            fromDecimals: fromToken.decimals,
            fromSymbol: fromToken.symbol,
            fromChain: fromChain,
            toChain: toChain,
            hashLock: hashLock.toString(),
            preimage: FormatUtils.encodeHexString(preimage),
            hashType: hashType,
          );
          await htlcSwapsService!.storeSwap(swap);
          ZenonAddressUtils.refreshBalance();
          addEvent(swap);
        },
      ).onError(
        (error, stackTrace) {
          addError(error.toString(), stackTrace);
        },
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  List<int> _generatePreimage() {
    const maxInt = 256;
    return List<int>.generate(
        htlcPreimageDefaultLength, (i) => Random.secure().nextInt(maxInt));
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
    return (await zenon!.ledger.getFrontierMomentum()).timestamp + duration;
  }
}
