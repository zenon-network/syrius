import 'package:equatable/equatable.dart';

/// QSR deposit and cost data required for sentinel creation.
class CreateSentinelQsrInfoData extends Equatable {
  /// Creates a new [CreateSentinelQsrInfoData].
  const CreateSentinelQsrInfoData({
    required this.cost,
    required this.deposit,
  });

  /// Creates a new [CreateSentinelQsrInfoData] from JSON.
  factory CreateSentinelQsrInfoData.fromJson(Map<String, dynamic> json) {
    return CreateSentinelQsrInfoData(
      cost: BigInt.parse(json['cost'] as String),
      deposit: BigInt.parse(json['deposit'] as String),
    );
  }

  /// The QSR cost required to register a sentinel.
  final BigInt cost;

  /// The QSR already deposited by the address.
  final BigInt deposit;

  /// Converts this data to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cost': cost.toString(),
      'deposit': deposit.toString(),
    };
  }

  @override
  List<Object?> get props => <Object?>[cost, deposit];
}
