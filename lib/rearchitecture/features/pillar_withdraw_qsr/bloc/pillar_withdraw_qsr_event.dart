part of 'pillar_withdraw_qsr_bloc.dart';

sealed class PillarWithdrawQsrEvent extends Equatable {
  const PillarWithdrawQsrEvent();

  @override
  List<Object> get props => <Object>[];
}

final class PillarWithdrawQsrRequested extends PillarWithdrawQsrEvent {
  const PillarWithdrawQsrRequested({required Address address})
    : _address = address;

  final Address _address;

  @override
  List<Object> get props => <Object>[_address];
}
