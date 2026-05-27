part of 'delegation_bloc.dart';

sealed class DelegationState extends Equatable {
  const DelegationState();

  @override
  List<Object> get props => <Object>[];
}

final class DelegationInitial extends DelegationState {
  const DelegationInitial();
}

final class DelegationFailure extends DelegationState {
  const DelegationFailure({required this.exception});

  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

final class DelegationDone extends DelegationState {
  const DelegationDone();
}

final class DelegationLoading extends DelegationState {
  const DelegationLoading();
}
