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

/// Returns whether [amount] can be minted for a token with the given
/// capabilities and supply bounds (`canMint && 0 < amount <= max - total`).
bool canMintTokenAmount({
  required BigInt amount,
  required BigInt totalSupply,
  required BigInt maxSupply,
  required bool isMintable,
  required bool isSelectedOwner,
}) {
  final TokenCapabilities caps = evaluateTokenCapabilities(
    isMintable: isMintable,
    isBurnable: false,
    totalSupply: totalSupply,
    maxSupply: maxSupply,
    isSelectedOwner: isSelectedOwner,
    isWalletOwner: isSelectedOwner,
  );
  if (!caps.canMint) {
    return false;
  }
  final BigInt remaining = maxSupply - totalSupply;
  return amount > BigInt.zero && amount <= remaining;
}

/// Returns whether [amount] can be burned from an account holding [balance]
/// of a token with [totalSupply]
/// (`canBurn && 0 < amount <= min(balance, totalSupply)`).
bool canBurnTokenAmount({
  required BigInt amount,
  required BigInt balance,
  required BigInt totalSupply,
  required bool isBurnable,
  required bool isSelectedOwner,
}) {
  final TokenCapabilities caps = evaluateTokenCapabilities(
    isMintable: false,
    isBurnable: isBurnable,
    totalSupply: totalSupply,
    maxSupply: totalSupply,
    isSelectedOwner: isSelectedOwner,
    isWalletOwner: isSelectedOwner,
  );
  if (!caps.canBurn) {
    return false;
  }
  return amount > BigInt.zero && amount <= balance && amount <= totalSupply;
}
