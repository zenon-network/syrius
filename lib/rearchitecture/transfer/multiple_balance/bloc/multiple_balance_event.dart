part of 'multiple_balance_bloc.dart';

/// The base class for events in [MultipleBalanceBloc].
///
/// Events extending this class are used to trigger state changes in the Bloc.
sealed class MultipleBalanceEvent extends Equatable {
  /// Constructs a new `TransferBalanceEvent`.
  const MultipleBalanceEvent();
}

/// Event to initiate fetching balances for all addresses.
class MultipleBalanceFetch extends MultipleBalanceEvent {
  /// Creates a new instance.
  const MultipleBalanceFetch({required this.addresses});
  /// The list of addresses whose balances are being managed.
  final List<String> addresses;
  @override
  List<Object?> get props => <Object?>[];
}
