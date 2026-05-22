part of 'update_pillar_bloc.dart';

sealed class UpdatePillarState extends Equatable {
  const UpdatePillarState();

  @override
  List<Object> get props => <Object>[];
}

final class UpdatePillarInitial extends UpdatePillarState {
  const UpdatePillarInitial();
}

final class UpdatePillarFailure extends UpdatePillarState {
  const UpdatePillarFailure({required this.exception});

  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

final class UpdatePillarDone extends UpdatePillarState {
  const UpdatePillarDone();
}

final class UpdatePillarLoading extends UpdatePillarState {
  const UpdatePillarLoading();
}
