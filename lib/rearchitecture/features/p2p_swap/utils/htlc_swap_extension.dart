import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';

/// Swap-specific projections for an [HtlcSwap].
extension HtlcSwapExtension on HtlcSwap {
  /// The HTLC funded by this wallet, if it has been created.
  ({int expirationTime, String id})? get fundedHtlc {
    if (direction == P2pSwapDirection.outgoing) {
      return (
        id: initialHtlcId,
        expirationTime: initialHtlcExpirationTime,
      );
    }

    final String? id = counterHtlcId;
    final int? expirationTime = counterHtlcExpirationTime;
    if (id == null || expirationTime == null) {
      return null;
    }

    return (id: id, expirationTime: expirationTime);
  }
}
