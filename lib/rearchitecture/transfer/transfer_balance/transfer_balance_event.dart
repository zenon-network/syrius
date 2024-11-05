part of 'transfer_balance_bloc.dart';

/// The base class for events in [TransferBalanceBloc].
///
/// Events extending this class are used to trigger state changes in the Bloc.
sealed class TransferBalanceEvent extends Equatable {
  /// Constructs a new `TransferBalanceEvent`.
  const TransferBalanceEvent();
}

/// Event to initiate fetching balances for all addresses.
class FetchBalances extends TransferBalanceEvent {
  @override
  List<Object?> get props => <Object?>[];
}
