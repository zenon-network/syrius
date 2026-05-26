part of 'undelegate_bloc.dart';

sealed class UndelegateState extends Equatable {
  const UndelegateState();

  @override
  List<Object> get props => <Object>[];
}

final class UndelegateInitial extends UndelegateState {
  const UndelegateInitial();
}

final class UndelegateFailure extends UndelegateState {
  const UndelegateFailure({required this.exception});

  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

final class UndelegateDone extends UndelegateState {
  const UndelegateDone();
}

final class UndelegateLoading extends UndelegateState {
  const UndelegateLoading();
}
