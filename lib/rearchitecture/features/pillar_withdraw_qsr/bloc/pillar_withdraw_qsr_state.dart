part of 'pillar_withdraw_qsr_bloc.dart';

sealed class PillarWithdrawQsrState extends Equatable {
  const PillarWithdrawQsrState();

  @override
  List<Object> get props => <Object>[];
}

final class PillarWithdrawQsrInitial extends PillarWithdrawQsrState {
  const PillarWithdrawQsrInitial();
}

final class PillarWithdrawQsrFailure extends PillarWithdrawQsrState {
  const PillarWithdrawQsrFailure({required this.exception});

  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

final class PillarWithdrawQsrPopulated extends PillarWithdrawQsrState {
  const PillarWithdrawQsrPopulated();
}

final class PillarWithdrawQsrLoading extends PillarWithdrawQsrState {
  const PillarWithdrawQsrLoading();
}
