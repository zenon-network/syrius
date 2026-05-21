part of 'pillar_deposit_qsr_bloc.dart';

sealed class PillarDepositQsrState extends Equatable {
  const PillarDepositQsrState();

  @override
  List<Object> get props => <Object>[];
}

final class PillarDepositQsrInitial extends PillarDepositQsrState {
  const PillarDepositQsrInitial();
}

final class PillarDepositQsrFailure extends PillarDepositQsrState {
  const PillarDepositQsrFailure({required this.exception});

  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

final class PillarDepositQsrDone extends PillarDepositQsrState {
  const PillarDepositQsrDone();
}

final class PillarDepositQsrLoading extends PillarDepositQsrState {
  const PillarDepositQsrLoading();
}
