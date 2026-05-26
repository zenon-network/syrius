part of 'undelegate_bloc.dart';

sealed class UndelegateEvent extends Equatable {
  const UndelegateEvent();

  @override
  List<Object> get props => <Object>[];
}

final class UndelegateRequested extends UndelegateEvent {
  const UndelegateRequested({
    required  this.address,
  });

  final Address address;

  @override
  List<Object> get props => <Object>[address];
}
