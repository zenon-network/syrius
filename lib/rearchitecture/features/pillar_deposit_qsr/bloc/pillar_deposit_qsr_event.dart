part of 'pillar_deposit_qsr_bloc.dart';

sealed class PillarDepositQsrEvent extends Equatable {
  const PillarDepositQsrEvent();

  @override
  List<Object> get props => <Object>[];
}

final class PillarDepositQsrRequested extends PillarDepositQsrEvent {
  const PillarDepositQsrRequested({
    required  this.address,
    required this.amount,
  });

  final Address address;
  final BigInt amount;

  @override
  List<Object> get props => <Object>[address, amount];
}
