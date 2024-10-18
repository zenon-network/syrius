import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';

class HtlcSwap extends P2pSwap {

  HtlcSwap({
    required this.hashLock,
    required this.initialHtlcId,
    required this.initialHtlcExpirationTime,
    required this.hashType,
    required super.id,
    required super.chainId,
    required super.type,
    required super.direction,
    required super.selfAddress,
    required super.counterpartyAddress,
    required super.fromAmount,
    required super.fromTokenStandard,
    required super.fromSymbol,
    required super.fromDecimals,
    required super.fromChain,
    required super.toChain,
    required super.startTime,
    required super.state,
    super.toAmount,
    super.toDecimals,
    super.toSymbol,
    super.toTokenStandard,
    this.counterHtlcId,
    this.counterHtlcExpirationTime,
    this.preimage,
  }) : super(mode: P2pSwapMode.htlc);

  HtlcSwap.fromJson(super.json)
      : hashLock = json['hashLock'],
        initialHtlcId = json['initialHtlcId'],
        initialHtlcExpirationTime = json['initialHtlcExpirationTime'],
        hashType = json['hashType'],
        counterHtlcId = json['counterHtlcId'],
        counterHtlcExpirationTime = json['counterHtlcExpirationTime'],
        preimage = json['preimage'],
        super.fromJson();
  final String hashLock;
  final String initialHtlcId;
  final int initialHtlcExpirationTime;
  final int hashType;
  String? counterHtlcId;
  int? counterHtlcExpirationTime;
  String? preimage;

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
