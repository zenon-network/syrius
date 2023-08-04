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

class JoinHtlcSwapBloc extends BaseBloc<HtlcSwap?> {
  void joinHtlcSwap({
    required HtlcInfo initialHtlc,
    required Token fromToken,
    required Token toToken,
    required BigInt fromAmount,
    required P2pSwapType swapType,
    required P2pSwapChain fromChain,
    required P2pSwapChain toChain,
    required int counterHtlcExpirationTime,
  }) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.htlc.create(
        fromToken,
        fromAmount,
        initialHtlc.timeLocked,
        counterHtlcExpirationTime,
        initialHtlc.hashType,
        initialHtlc.keyMaxSize,
        initialHtlc.hashLock,
      );
      KeyPair blockSigningKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(initialHtlc.hashLocked.toString()),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'join swap',
              blockSigningKey: blockSigningKeyPair, waitForRequiredPlasma: true)
          .then(
        (response) async {
          final swap = HtlcSwap(
            id: initialHtlc.id.toString(),
            chainId: response.chainIdentifier,
            type: swapType,
            direction: P2pSwapDirection.incoming,
            selfAddress: initialHtlc.hashLocked.toString(),
            counterHtlcId: response.hash.toString(),
            counterHtlcExpirationTime: counterHtlcExpirationTime,
            counterpartyAddress: initialHtlc.timeLocked.toString(),
            state: P2pSwapState.active,
            startTime: DateTimeUtils.unixTimeNow,
            initialHtlcId: initialHtlc.id.toString(),
            initialHtlcExpirationTime: initialHtlc.expirationTime,
            fromAmount: fromAmount,
            fromTokenStandard: fromToken.tokenStandard.toString(),
            fromDecimals: fromToken.decimals,
            fromSymbol: fromToken.symbol,
            fromChain: fromChain,
            toAmount: initialHtlc.amount,
            toTokenStandard: toToken.tokenStandard.toString(),
            toDecimals: toToken.decimals,
            toSymbol: toToken.symbol,
            toChain: toChain,
            hashLock: FormatUtils.encodeHexString(initialHtlc.hashLock),
            hashType: initialHtlc.hashType,
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
}
