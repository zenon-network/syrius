import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Maximum permitted length for a ZTS token domain (matches go-zenon's
/// `TokenDomainMaxLength` protocol constant).
const int kTokenDomainMaxLength = 128;

/// Minimum permitted decimal precision for a ZTS token.
const int kTokenDecimalsMin = 0;

/// Maximum permitted decimal precision for a ZTS token.
const int kTokenDecimalsMax = 18;

/// Linear-time equivalent of `znn_sdk_dart`'s `tokenNameRegExp`
/// (`^([a-zA-Z0-9]+[-._]?)*[a-zA-Z0-9]$`) without nested-quantifier
/// backtracking.
final RegExp kTokenNameRegExp = RegExp(
  r'^[a-zA-Z0-9]+([-._][a-zA-Z0-9]+)*$',
);

/// Validation failure reasons for a ZTS token name.
enum TokenNameValidationError {
  /// The token name is empty.
  empty,

  /// The token name exceeds [tokenNameMaxLength].
  tooLong,

  /// The token name does not match [kTokenNameRegExp].
  invalidCharacters,
}

/// Validation failure reasons for a ZTS token symbol.
enum TokenSymbolValidationError {
  /// The token symbol is empty.
  empty,

  /// The token symbol exceeds [tokenSymbolMaxLength].
  tooLong,

  /// The token symbol does not match `tokenSymbolRegExp`.
  invalidCharacters,

  /// The token symbol is reserved (e.g. `ZNN`, `QSR`).
  reserved,
}

/// Validation failure reasons for a ZTS token domain.
enum TokenDomainValidationError {
  /// The token domain is empty.
  empty,

  /// The token domain exceeds [kTokenDomainMaxLength].
  tooLong,

  /// The token domain does not match `tokenDomainRegExp`.
  invalidFormat,
}

/// Derived validation outcome and effective max supply for ZTS token creation.
class TokenSupplyMetricsValidation extends Equatable {
  /// Creates a [TokenSupplyMetricsValidation].
  const TokenSupplyMetricsValidation({
    required this.isValid,
    required this.effectiveMaxSupply,
  });

  /// Whether decimals, max supply, and total supply satisfy protocol rules.
  final bool isValid;

  /// Effective on-chain max supply (`maxSupply` when mintable, else
  /// `totalSupply`).
  final BigInt effectiveMaxSupply;

  @override
  List<Object> get props => <Object>[isValid, effectiveMaxSupply];
}

/// Returns whether [decimals] is within the protocol-valid `[0, 18]` range.
bool isValidTokenDecimals(int decimals) =>
    decimals >= kTokenDecimalsMin && decimals <= kTokenDecimalsMax;

/// Returns whether [value] is non-empty and within [kTokenDomainMaxLength].
bool isValidTokenDomainLength(String value) =>
    value.isNotEmpty && value.length <= kTokenDomainMaxLength;

/// Validates a ZTS token [name], returning `null` when valid.
TokenNameValidationError? validateTokenNameError(String name) {
  if (name.isEmpty) {
    return TokenNameValidationError.empty;
  }
  if (name.length > tokenNameMaxLength) {
    return TokenNameValidationError.tooLong;
  }
  if (!kTokenNameRegExp.hasMatch(name)) {
    return TokenNameValidationError.invalidCharacters;
  }
  return null;
}

/// Validates a ZTS token [symbol], returning `null` when valid.
TokenSymbolValidationError? validateTokenSymbolError(String symbol) {
  if (symbol.isEmpty) {
    return TokenSymbolValidationError.empty;
  }
  if (symbol.length > tokenSymbolMaxLength) {
    return TokenSymbolValidationError.tooLong;
  }
  if (!tokenSymbolRegExp.hasMatch(symbol)) {
    return TokenSymbolValidationError.invalidCharacters;
  }
  if (tokenSymbolExceptions.contains(symbol)) {
    return TokenSymbolValidationError.reserved;
  }
  return null;
}

/// Validates a ZTS token [domain], returning `null` when valid.
TokenDomainValidationError? validateTokenDomainError(String domain) {
  if (domain.isEmpty) {
    return TokenDomainValidationError.empty;
  }
  if (!isValidTokenDomainLength(domain)) {
    return TokenDomainValidationError.tooLong;
  }
  if (!tokenDomainRegExp.hasMatch(domain)) {
    return TokenDomainValidationError.invalidFormat;
  }
  return null;
}

/// Resolves the effective on-chain max supply for a new token.
///
/// Mintable tokens use [maxSupplyInput]; fixed-supply (non-mintable) tokens set
/// max supply equal to [totalSupply].
BigInt resolveEffectiveTokenMaxSupply({
  required bool isMintable,
  required BigInt totalSupply,
  required BigInt maxSupplyInput,
}) => isMintable ? maxSupplyInput : totalSupply;

/// Validates ZTS token supply inputs (`decimals`, `totalSupplyText`,
/// `maxSupplyText`) against [isMintable] and [maxSupplyCap].
///
/// Defaults [maxSupplyCap] to [kBigP255m1] and parses inputs using
/// [scaleDecimals] (which defaults to [decimals]).
TokenSupplyMetricsValidation validateTokenSupplyMetrics({
  required bool isMintable,
  required String totalSupplyText,
  required String maxSupplyText,
  required int decimals,
  BigInt? maxSupplyCap,
  int? scaleDecimals,
}) {
  final BigInt cap = maxSupplyCap ?? kBigP255m1;
  final int effectiveScale = scaleDecimals ?? decimals;
  final bool decimalsOk = isValidTokenDecimals(decimals);
  final BigInt? totalSupply = effectiveScale >= 0
      ? _tryParseScaledAmount(totalSupplyText, effectiveScale)
      : null;
  final BigInt? maxSupplyInput = effectiveScale >= 0
      ? _tryParseScaledAmount(maxSupplyText, effectiveScale)
      : null;

  final BigInt effectiveMax = resolveEffectiveTokenMaxSupply(
    isMintable: isMintable,
    totalSupply: totalSupply ?? BigInt.zero,
    maxSupplyInput: maxSupplyInput ?? BigInt.zero,
  );

  if (!decimalsOk || totalSupply == null) {
    return TokenSupplyMetricsValidation(
      isValid: false,
      effectiveMaxSupply: effectiveMax,
    );
  }

  if (isMintable) {
    final bool maxOk =
        maxSupplyInput != null &&
        maxSupplyInput >= kMinTokenTotalMaxSupply &&
        maxSupplyInput <= cap;
    final bool totalOk =
        maxOk && totalSupply >= BigInt.zero && totalSupply <= maxSupplyInput;
    return TokenSupplyMetricsValidation(
      isValid: maxOk && totalOk,
      effectiveMaxSupply: effectiveMax,
    );
  }

  final bool totalOk =
      totalSupply >= kMinTokenTotalMaxSupply && totalSupply <= cap;
  return TokenSupplyMetricsValidation(
    isValid: totalOk,
    effectiveMaxSupply: effectiveMax,
  );
}

BigInt? _tryParseScaledAmount(String text, int decimals) {
  if (text.isEmpty) {
    return null;
  }
  final List<String> parts = text.split('.');
  if (parts.length > 2) {
    return null;
  }
  if (parts.length == 2 && parts[1].length > decimals) {
    return null;
  }
  try {
    return text.extractDecimals(decimals);
  } on Object {
    return null;
  }
}
