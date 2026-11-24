// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'p2p_swap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HtlcSwap _$HtlcSwapFromJson(Map<String, dynamic> json) => HtlcSwap(
  hashLock: json['hashLock'] as String,
  initialHtlcId: json['initialHtlcId'] as String,
  initialHtlcExpirationTime: (json['initialHtlcExpirationTime'] as num).toInt(),
  hashType: (json['hashType'] as num).toInt(),
  id: json['id'] as String,
  chainId: (json['chainId'] as num).toInt(),
  type: $enumDecode(_$P2pSwapTypeEnumMap, json['type']),
  direction: $enumDecode(_$P2pSwapDirectionEnumMap, json['direction']),
  selfAddress: json['selfAddress'] as String,
  counterpartyAddress: json['counterpartyAddress'] as String,
  fromAmount: BigInt.parse(json['fromAmount'] as String),
  fromToken: Token.fromJson(json['fromToken'] as Map<String, dynamic>),
  fromChain: $enumDecode(_$P2pSwapChainEnumMap, json['fromChain']),
  toChain: $enumDecode(_$P2pSwapChainEnumMap, json['toChain']),
  startTime: (json['startTime'] as num).toInt(),
  state: $enumDecode(_$P2pSwapStateEnumMap, json['state']),
  mode:
      $enumDecodeNullable(_$P2pSwapModeEnumMap, json['mode']) ??
      P2pSwapMode.htlc,
  toAmount: json['toAmount'] == null
      ? null
      : BigInt.parse(json['toAmount'] as String),
  toToken: json['toToken'] == null
      ? null
      : Token.fromJson(json['toToken'] as Map<String, dynamic>),
  counterHtlcId: json['counterHtlcId'] as String?,
  counterHtlcExpirationTime: (json['counterHtlcExpirationTime'] as num?)
      ?.toInt(),
  preimage: json['preimage'] as String?,
);

Map<String, dynamic> _$HtlcSwapToJson(HtlcSwap instance) => <String, dynamic>{
  'hashLock': instance.hashLock,
  'initialHtlcId': instance.initialHtlcId,
  'initialHtlcExpirationTime': instance.initialHtlcExpirationTime,
  'hashType': instance.hashType,
  'id': instance.id,
  'chainId': instance.chainId,
  'type': _$P2pSwapTypeEnumMap[instance.type]!,
  'direction': _$P2pSwapDirectionEnumMap[instance.direction]!,
  'selfAddress': instance.selfAddress,
  'counterpartyAddress': instance.counterpartyAddress,
  'fromAmount': instance.fromAmount.toString(),
  'fromToken': instance.fromToken.toJson(),
  'fromChain': _$P2pSwapChainEnumMap[instance.fromChain]!,
  'toChain': _$P2pSwapChainEnumMap[instance.toChain]!,
  'startTime': instance.startTime,
  'state': _$P2pSwapStateEnumMap[instance.state]!,
  'mode': _$P2pSwapModeEnumMap[instance.mode]!,
  'toAmount': instance.toAmount?.toString(),
  'toToken': instance.toToken?.toJson(),
  'counterHtlcId': instance.counterHtlcId,
  'counterHtlcExpirationTime': instance.counterHtlcExpirationTime,
  'preimage': instance.preimage,
};

const _$P2pSwapTypeEnumMap = {
  P2pSwapType.native: 'native',
  P2pSwapType.crosschain: 'crosschain',
};

const _$P2pSwapDirectionEnumMap = {
  P2pSwapDirection.outgoing: 'outgoing',
  P2pSwapDirection.incoming: 'incoming',
};

const _$P2pSwapChainEnumMap = {
  P2pSwapChain.nom: 'nom',
  P2pSwapChain.btc: 'btc',
  P2pSwapChain.other: 'other',
};

const _$P2pSwapStateEnumMap = {
  P2pSwapState.pending: 'pending',
  P2pSwapState.active: 'active',
  P2pSwapState.completed: 'completed',
  P2pSwapState.reclaimable: 'reclaimable',
  P2pSwapState.unsuccessful: 'unsuccessful',
  P2pSwapState.error: 'error',
};

const _$P2pSwapModeEnumMap = {P2pSwapMode.htlc: 'htlc'};
