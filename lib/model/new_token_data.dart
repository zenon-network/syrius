/// Complete data required to issue a new ZTS token.
class NewTokenData {
  /// Creates [NewTokenData].
  const NewTokenData({
    required this.address,
    required this.tokenName,
    required this.tokenSymbol,
    required this.tokenDomain,
    required this.totalSupply,
    required this.decimals,
    required this.maxSupply,
    required this.isMintable,
    required this.isOwnerBurnOnly,
    required this.isUtility,
  });

  /// Creates an empty token draft for [address].
  factory NewTokenData.initial({required String address}) {
    return NewTokenData(
      address: address,
      tokenName: '',
      tokenSymbol: '',
      tokenDomain: '',
      totalSupply: BigInt.zero,
      decimals: 0,
      maxSupply: BigInt.zero,
      isMintable: false,
      isOwnerBurnOnly: false,
      isUtility: true,
    );
  }

  /// Creates a copy with selected fields replaced.
  NewTokenData copyWith({
    String? address,
    String? tokenName,
    String? tokenSymbol,
    String? tokenDomain,
    BigInt? totalSupply,
    int? decimals,
    BigInt? maxSupply,
    bool? isMintable,
    bool? isOwnerBurnOnly,
    bool? isUtility,
  }) {
    return NewTokenData(
      address: address ?? this.address,
      tokenName: tokenName ?? this.tokenName,
      tokenSymbol: tokenSymbol ?? this.tokenSymbol,
      tokenDomain: tokenDomain ?? this.tokenDomain,
      totalSupply: totalSupply ?? this.totalSupply,
      decimals: decimals ?? this.decimals,
      maxSupply: maxSupply ?? this.maxSupply,
      isMintable: isMintable ?? this.isMintable,
      isOwnerBurnOnly: isOwnerBurnOnly ?? this.isOwnerBurnOnly,
      isUtility: isUtility ?? this.isUtility,
    );
  }

  /// Address issuing the token.
  final String address;

  /// Token name.
  final String tokenName;

  /// Token symbol.
  final String tokenSymbol;

  /// Token domain.
  final String tokenDomain;

  /// Initial total token supply.
  final BigInt totalSupply;

  /// Number of token decimals.
  final int decimals;

  /// Maximum token supply.
  final BigInt maxSupply;

  /// Whether the token can be minted after issuance.
  final bool isMintable;

  /// Whether only the owner can burn the token.
  final bool isOwnerBurnOnly;

  /// Whether the token is a utility token.
  final bool isUtility;
}
