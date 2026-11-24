part of 'start_p2p_swap_bloc.dart';

/// Base class for start-HTLC-swap events.
sealed class StartP2pSwapEvent extends Equatable {
  /// Creates a [StartP2pSwapEvent].
  const StartP2pSwapEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests creation of an outgoing HTLC swap.
final class StartP2pSwapRequested extends StartP2pSwapEvent {
  /// Creates a [StartP2pSwapRequested] event.
  const StartP2pSwapRequested({
    required this.selfAddress,
    required this.counterpartyAddress,
    required this.fromToken,
    required this.fromAmount,
    this.hashType = htlcHashTypeSha3,
    this.swapType = P2pSwapType.native,
    this.fromChain = P2pSwapChain.nom,
    this.toChain = P2pSwapChain.nom,
    this.initialHtlcDuration = kInitialHtlcDuration,
  });

  /// Address funding the HTLC.
  final Address selfAddress;

  /// Address that can unlock the HTLC.
  final Address counterpartyAddress;

  /// Token locked in the HTLC.
  final Token fromToken;

  /// Amount locked in the HTLC.
  final BigInt fromAmount;

  /// Hash algorithm used for the hash lock.
  final int hashType;

  /// Type of P2P swap being started.
  final P2pSwapType swapType;

  /// Chain from which the swap originates.
  final P2pSwapChain fromChain;

  /// Chain on which the counterparty pays.
  final P2pSwapChain toChain;

  /// Initial HTLC lifetime.
  final Duration initialHtlcDuration;

  @override
  List<Object?> get props => <Object?>[
    selfAddress,
    counterpartyAddress,
    fromToken,
    fromAmount,
    hashType,
    swapType,
    fromChain,
    toChain,
    initialHtlcDuration,
  ];
}
