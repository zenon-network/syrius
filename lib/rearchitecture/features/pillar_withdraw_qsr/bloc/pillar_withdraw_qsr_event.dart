part of 'pillar_withdraw_qsr_bloc.dart';

sealed class PillarWithdrawQsrEvent extends Equatable {
  const PillarWithdrawQsrEvent();

  @override
  List<Object> get props => <Object>[];
}

final class PillarWithdrawQsrRequested extends PillarWithdrawQsrEvent {
  const PillarWithdrawQsrRequested({required this.address});

  final Address address;

  @override
  List<Object> get props => <Object>[address];
}
