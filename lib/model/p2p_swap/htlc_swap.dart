import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';

class HtlcSwap extends P2pSwap {
  final String hashLock;
  final String initialHtlcId;
  final int initialHtlcExpirationTime;
  final int hashType;
  String? counterHtlcId;
  int? counterHtlcExpirationTime;
  String? preimage;

  HtlcSwap({
    required id,
    required chainId,
    required type,
    required direction,
    required selfAddress,
    required counterpartyAddress,
    required fromAmount,
    required fromTokenStandard,
    required fromSymbol,
    required fromDecimals,
    required fromChain,
    required toChain,
    required startTime,
    required state,
    toAmount,
    toTokenStandard,
    toSymbol,
    toDecimals,
    required this.hashLock,
    required this.initialHtlcId,
    required this.initialHtlcExpirationTime,
    required this.hashType,
    this.counterHtlcId,
    this.counterHtlcExpirationTime,
    this.preimage,
  }) : super(
          id: id,
          chainId: chainId,
          type: type,
          mode: P2pSwapMode.htlc,
          direction: direction,
          selfAddress: selfAddress,
          counterpartyAddress: counterpartyAddress,
          fromAmount: fromAmount,
          fromTokenStandard: fromTokenStandard,
          fromSymbol: fromSymbol,
          fromDecimals: fromDecimals,
          fromChain: fromChain,
          toChain: toChain,
          startTime: startTime,
          state: state,
          toAmount: toAmount,
          toTokenStandard: toTokenStandard,
          toSymbol: toSymbol,
          toDecimals: toDecimals,
        );

  HtlcSwap.fromJson(Map<String, dynamic> json)
      : hashLock = json['hashLock'],
        initialHtlcId = json['initialHtlcId'],
        initialHtlcExpirationTime = json['initialHtlcExpirationTime'],
        hashType = json['hashType'],
        counterHtlcId = json['counterHtlcId'],
        counterHtlcExpirationTime = json['counterHtlcExpirationTime'],
        preimage = json['preimage'],
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    data['hashLock'] = hashLock;
    data['initialHtlcId'] = initialHtlcId;
    data['initialHtlcExpirationTime'] = initialHtlcExpirationTime;
    data['hashType'] = hashType;
    data['counterHtlcId'] = counterHtlcId;
    data['counterHtlcExpirationTime'] = counterHtlcExpirationTime;
    data['preimage'] = preimage;
    return data;
  }
}
