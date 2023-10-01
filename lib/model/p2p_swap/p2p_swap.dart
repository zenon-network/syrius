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

class P2pSwap {
  final String id;
  final int chainId;
  final P2pSwapType type;
  final P2pSwapMode mode;
  final P2pSwapDirection direction;
  final String selfAddress;
  final String counterpartyAddress;
  final BigInt fromAmount;
  final String fromTokenStandard;
  final String fromSymbol;
  final int fromDecimals;
  final P2pSwapChain fromChain;
  final P2pSwapChain toChain;
  final int startTime;
  P2pSwapState state;
  BigInt? toAmount;
  String? toTokenStandard;
  String? toSymbol;
  int? toDecimals;

  P2pSwap(
      {required this.id,
      required this.chainId,
      required this.type,
      required this.mode,
      required this.direction,
      required this.selfAddress,
      required this.counterpartyAddress,
      required this.fromAmount,
      required this.fromTokenStandard,
      required this.fromSymbol,
      required this.fromDecimals,
      required this.fromChain,
      required this.toChain,
      required this.startTime,
      required this.state,
      this.toAmount,
      this.toTokenStandard,
      this.toSymbol,
      this.toDecimals});

  P2pSwap.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        chainId = json['chainId'],
        type = P2pSwapType.values.byName(json['type']),
        mode = P2pSwapMode.values.byName(json['mode']),
        direction = P2pSwapDirection.values.byName(json['direction']),
        selfAddress = json['selfAddress'],
        counterpartyAddress = json['counterpartyAddress'],
        fromAmount = BigInt.parse(json['fromAmount'].toString()),
        fromTokenStandard = json['fromTokenStandard'],
        fromSymbol = json['fromSymbol'],
        fromDecimals = json['fromDecimals'],
        fromChain = P2pSwapChain.values.byName(json['fromChain']),
        toChain = P2pSwapChain.values.byName(json['toChain']),
        startTime = json['startTime'],
        state = P2pSwapState.values.byName(json['state']),
        toAmount = BigInt.tryParse(json['toAmount'].toString()),
        toTokenStandard = json['toTokenStandard'],
        toSymbol = json['toSymbol'],
        toDecimals = json['toDecimals'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'chainId': chainId,
        'type': type.name,
        'mode': mode.name,
        'direction': direction.name,
        'selfAddress': selfAddress,
        'counterpartyAddress': counterpartyAddress,
        'fromAmount': fromAmount.toString(),
        'fromTokenStandard': fromTokenStandard,
        'fromSymbol': fromSymbol,
        'fromDecimals': fromDecimals,
        'fromChain': fromChain.name,
        'toChain': toChain.name,
        'startTime': startTime,
        'state': state.name,
        'toAmount': toAmount?.toString(),
        'toTokenStandard': toTokenStandard,
        'toSymbol': toSymbol,
        'toDecimals': toDecimals,
      };
}
