part of 'latest_transactions_bloc.dart';

/// The generic class for the events used in [LatestTransactionsBloc]
sealed class LatestTransactionsEvent extends Equatable {
  /// Creates a new instance.
  const LatestTransactionsEvent();
}

/// Event to be used when we want to fetch the latest transactions of an
/// [address]
class LatestTransactionsRequested extends LatestTransactionsEvent {
  /// Creates a new instance.
  const LatestTransactionsRequested({required this.address});
  /// The [address] whose latest transactions are being requested.
  final Address address;
  @override
  List<Object?> get props => <Object>[address];
}

/// Event to be used when we want to refresh the list of the latest
/// transactions
class LatestTransactionsRefreshRequested extends LatestTransactionsEvent {
  /// Creates a new instance.
  const LatestTransactionsRefreshRequested({required this.address});
  /// The [address] whose latest transactions are being requested.
  final Address address;
  @override
  List<Object?> get props => <Object>[address];
}
