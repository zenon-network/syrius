part of 'undelegate_bloc.dart';

/// Base class for all undelegate events.
sealed class UndelegateEvent extends Equatable {
  /// Creates a new [UndelegateEvent].
  const UndelegateEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests an undelegation transaction for the current delegation.
final class UndelegateRequested extends UndelegateEvent {
  /// Creates a new [UndelegateRequested] event.
  const UndelegateRequested({
    required this.address,
  });

  /// The delegator address.
  final Address address;

  @override
  List<Object> get props => <Object>[address];
}
