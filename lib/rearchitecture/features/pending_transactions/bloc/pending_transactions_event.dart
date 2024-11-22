part of 'pending_transactions_bloc.dart';

/// The generic class for the events used in [PendingTransactionsBloc]
sealed class PendingTransactionsEvent extends Equatable {
  /// Creates a new instance.
  const PendingTransactionsEvent(this.address);

  /// The [address] for which the pending transactions are fetched.
  final Address address;
}

/// Event to be used when we want to fetch the pending transactions for an
/// [address]
class PendingTransactionsRequested extends PendingTransactionsEvent {
  /// Creates a new instance.
  const PendingTransactionsRequested(super.address);
  @override
  List<Object?> get props => <Object>[address];
}

/// Event to be used when we want to refresh the list of the pending
/// transactions
class PendingTransactionsRefreshRequested extends PendingTransactionsEvent {
  /// Creates a new instance.
  const PendingTransactionsRefreshRequested(super.address);
  @override
  List<Object?> get props => <Object>[address];
}
