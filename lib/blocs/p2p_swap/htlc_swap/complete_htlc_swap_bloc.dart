import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/htlc_swap.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CompleteHtlcSwapBloc extends BaseBloc<HtlcSwap?> {
  final safeExpirationThreshold = const Duration(minutes: 10);

  Future<void> completeHtlcSwap({
    required HtlcSwap swap,
  }) async {
    try {
      addEvent(null);
      final htlcId = swap.direction == P2pSwapDirection.outgoing
          ? swap.counterHtlcId!
          : swap.initialHtlcId;

      // Make sure that the HTLC exists and has a safe amount of time left
      // until expiration.
      final htlc = await zenon!.embedded.htlc.getById(Hash.parse(htlcId));
      if (htlc.expirationTime <=
          DateTimeUtils.unixTimeNow + safeExpirationThreshold.inSeconds) {
        throw 'The swap will expire too soon for a safe swap.';
      }

      if (htlc.keyMaxSize <
          FormatUtils.decodeHexString(swap.preimage!).length) {
        throw 'The swap secret size exceeds the maximum allowed size.';
      }

      AccountBlockTemplate transactionParams = zenon!.embedded.htlc.unlock(
          Hash.parse(htlcId), FormatUtils.decodeHexString(swap.preimage!));
      KeyPair blockSigningKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(swap.selfAddress.toString()),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'complete swap',
              blockSigningKey: blockSigningKeyPair, waitForRequiredPlasma: true)
          .then(
        (response) async {
          swap.state = P2pSwapState.completed;
          await htlcSwapsService!.storeSwap(swap);
          AddressUtils.refreshBalance();
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
