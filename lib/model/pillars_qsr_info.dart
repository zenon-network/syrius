class PillarsQsrInfo {
  PillarsQsrInfo({
    required this.cost,
    required this.deposit,
  });

  factory PillarsQsrInfo.fromJson(Map<String, dynamic> json) {
    return PillarsQsrInfo(
      cost: BigInt.parse(json['cost'] as String),
      deposit: BigInt.parse(json['deposit'] as String),
    );
  }

  final BigInt cost;
  final BigInt deposit;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cost': cost.toString(),
      'deposit': deposit.toString(),
    };
  }
}
