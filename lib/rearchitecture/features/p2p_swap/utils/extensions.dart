import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';

export 'htlc_swap_extension.dart';

/// Provides localized display text for a peer-to-peer swap state.
extension P2pSwapStateLocalization on P2pSwapState {
  /// Returns the localized status text for this state.
  String statusText(BuildContext context) => switch (this) {
    P2pSwapState.pending => context.l10n.starting,
    P2pSwapState.active => context.l10n.active,
    P2pSwapState.completed => context.l10n.completed,
    P2pSwapState.reclaimable => context.l10n.reclaimDeposit,
    P2pSwapState.unsuccessful => context.l10n.unsuccessful,
    P2pSwapState.error => context.l10n.error,
  };
}
