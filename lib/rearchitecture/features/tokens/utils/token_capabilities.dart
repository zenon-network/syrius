import 'package:equatable/equatable.dart';

/// Action visibility and enablement flags for a ZTS token card.
class TokenCapabilities extends Equatable {
  /// Creates a [TokenCapabilities].
  const TokenCapabilities({
    required this.showOwnBadge,
    required this.canTransferOwnership,
    required this.showMintButton,
    required this.canMint,
    required this.canBurn,
  });

  /// Whether the token owner belongs to any address in the current wallet.
  final bool showOwnBadge;

  /// Whether the currently selected address can transfer token ownership.
  final bool canTransferOwnership;

  /// Whether the mint icon button is visible (`isMintable && total < max`).
  final bool showMintButton;

  /// Whether the currently selected address can actually invoke minting.
  final bool canMint;

  /// Whether the currently selected address can burn the token.
  final bool canBurn;

  @override
  List<Object> get props => <Object>[
    showOwnBadge,
    canTransferOwnership,
    showMintButton,
    canMint,
    canBurn,
  ];
}

/// Evaluates ZTS token action visibility and authorization flags from token
/// metadata and ownership predicates.
TokenCapabilities evaluateTokenCapabilities({
  required bool isMintable,
  required bool isBurnable,
  required BigInt totalSupply,
  required BigInt maxSupply,
  required bool isSelectedOwner,
  required bool isWalletOwner,
}) {
  final bool showMintButton = isMintable && totalSupply < maxSupply;
  return TokenCapabilities(
    showOwnBadge: isWalletOwner,
    canTransferOwnership: isSelectedOwner,
    showMintButton: showMintButton,
    canMint: showMintButton && isSelectedOwner,
    canBurn: isBurnable || isSelectedOwner,
  );
}
