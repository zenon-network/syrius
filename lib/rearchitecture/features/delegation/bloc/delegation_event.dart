part of 'delegation_bloc.dart';

sealed class DelegationEvent extends Equatable {
  const DelegationEvent();

  @override
  List<Object> get props => <Object>[];
}

final class DelegationRequested extends DelegationEvent {
  const DelegationRequested({
    required this.address,
    required this.pillarName,
  });

  final Address address;
  final String pillarName;

  @override
  List<Object> get props => <Object>[address, pillarName];
}
