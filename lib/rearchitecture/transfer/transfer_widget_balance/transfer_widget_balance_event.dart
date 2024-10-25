part of 'transfer_widget_balance_bloc.dart';

sealed class TransferWidgetsBalanceEvent extends Equatable {
  const TransferWidgetsBalanceEvent();
}

class FetchBalances extends TransferWidgetsBalanceEvent {
  @override
  List<Object?> get props => [];
}