part of 'transfer_balance_bloc.dart';

sealed class TransferBalanceEvent extends Equatable {
  const TransferBalanceEvent();
}

class FetchBalances extends TransferBalanceEvent {
  @override
  List<Object?> get props => [];
}