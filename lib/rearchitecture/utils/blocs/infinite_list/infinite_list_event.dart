part of 'infinite_list_bloc.dart';

/// The generic class for the events used in [InfiniteListBloc]
sealed class InfiniteListEvent extends Equatable {
  /// Creates a new instance.
  const InfiniteListEvent({required this.address});

  /// The [address] for which data will be fetched.
  final Address address;
}

/// Event to be used when we want to fetch the latest transactions of an
/// [address]
class InfiniteListRequested extends InfiniteListEvent {
  /// Creates a new instance.
  const InfiniteListRequested({required super.address});

  @override
  List<Object?> get props => <Object>[address];
}

/// Event to be used when we want to fetch more latest transactions of an
/// [address]
class InfiniteListMoreRequested extends InfiniteListEvent {
  /// Creates a new instance.
  const InfiniteListMoreRequested({required super.address});

  @override
  List<Object?> get props => <Object>[address];
}

/// Event to be used when we want to refresh the list of the latest
/// transactions
class InfiniteListRefreshRequested extends InfiniteListEvent {
  /// Creates a new instance.
  const InfiniteListRefreshRequested({required super.address});

  @override
  List<Object?> get props => <Object>[address];
}
