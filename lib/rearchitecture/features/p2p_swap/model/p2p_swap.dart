import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'p2p_swap.freezed.dart';

part 'p2p_swap.g.dart';

// The name of the variables are self-explanatory
// ignore_for_file: public_member_api_docs
enum P2pSwapType {
  native,
  crosschain,
}

enum P2pSwapState {
  pending,
  active,
  completed,
  reclaimable,
  unsuccessful,
  error,
}

enum P2pSwapMode {
  htlc,
}

enum P2pSwapDirection {
  outgoing,
  incoming,
}

enum P2pSwapChain {
  nom,
  btc,
  other,
}

@Freezed(unionKey: 'mode')
sealed class P2pSwap with _$P2pSwap {
  const P2pSwap._();

  @FreezedUnionValue('htlc')
  // Freezed reads JsonSerializable options from union factory constructors.
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory P2pSwap.htlc({
    required String hashLock,
    required String initialHtlcId,
    required int initialHtlcExpirationTime,
    required int hashType,
    required String id,
    required int chainId,
    required P2pSwapType type,
    required P2pSwapDirection direction,
    required String selfAddress,
    required String counterpartyAddress,
    required BigInt fromAmount,
    required Token fromToken,
    required P2pSwapChain fromChain,
    required P2pSwapChain toChain,
    required int startTime,
    required P2pSwapState state,
    @Default(P2pSwapMode.htlc) P2pSwapMode mode,
    BigInt? toAmount,
    Token? toToken,
    String? counterHtlcId,
    int? counterHtlcExpirationTime,
    String? preimage,
  }) = HtlcSwap;

  factory P2pSwap.fromJson(Map<String, dynamic> json) =>
      _$P2pSwapFromJson(_normalizeTokenJson(json));
}

Map<String, dynamic> _normalizeTokenJson(Map<String, dynamic> json) {
  final Map<String, dynamic> normalizedJson = Map<String, dynamic>.of(json);

  normalizedJson['fromToken'] ??= _legacyTokenJson(
    tokenStandard: json['fromTokenStandard'] as String,
    symbol: json['fromSymbol'] as String,
    decimals: (json['fromDecimals'] as num).toInt(),
  );

  if (normalizedJson['toToken'] == null &&
      json['toTokenStandard'] != null &&
      json['toSymbol'] != null &&
      json['toDecimals'] != null) {
    normalizedJson['toToken'] = _legacyTokenJson(
      tokenStandard: json['toTokenStandard'] as String,
      symbol: json['toSymbol'] as String,
      decimals: (json['toDecimals'] as num).toInt(),
    );
  }

  return normalizedJson;
}

Map<String, dynamic> _legacyTokenJson({
  required String tokenStandard,
  required String symbol,
  required int decimals,
}) => <String, dynamic>{
  'name': symbol,
  'symbol': symbol,
  'domain': '',
  'totalSupply': '0',
  'decimals': decimals,
  'owner': emptyAddress.toString(),
  'tokenStandard': tokenStandard,
  'maxSupply': '0',
  'isBurnable': false,
  'isMintable': false,
  'isUtility': false,
};
