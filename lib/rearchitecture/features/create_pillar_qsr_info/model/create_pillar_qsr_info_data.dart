import 'package:equatable/equatable.dart';

class CreatePillarQsrInfoData extends Equatable{
  CreatePillarQsrInfoData({
    required this.cost,
    required this.deposit,
  });

  factory CreatePillarQsrInfoData.fromJson(Map<String, dynamic> json) {
    return CreatePillarQsrInfoData(
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

  @override
  List<Object?> get props => <Object?>[cost, deposit];
}
