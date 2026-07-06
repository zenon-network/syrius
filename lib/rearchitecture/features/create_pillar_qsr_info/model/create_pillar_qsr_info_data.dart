import 'package:equatable/equatable.dart';

/// QSR cost and deposit values required to create a pillar.
class CreatePillarQsrInfoData extends Equatable {
  /// Creates pillar QSR info data.
  const CreatePillarQsrInfoData({
    required this.cost,
    required this.deposit,
  });

  /// Creates pillar QSR info data from JSON.
  factory CreatePillarQsrInfoData.fromJson(Map<String, dynamic> json) {
    return CreatePillarQsrInfoData(
      cost: BigInt.parse(json['cost'] as String),
      deposit: BigInt.parse(json['deposit'] as String),
    );
  }

  /// QSR amount required to create the pillar.
  final BigInt cost;

  /// QSR amount deposited for pillar creation.
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
