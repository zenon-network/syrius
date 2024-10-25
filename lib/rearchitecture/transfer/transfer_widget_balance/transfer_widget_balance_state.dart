part of 'transfer_widget_balance_bloc.dart';

enum TransferWidgetBalanceStatus { initial, loading, success, failure }

class TransferWidgetBalanceState extends Equatable {

  const TransferWidgetBalanceState({
    required this.status,
    this.data,
    this.error,
  });

  final TransferWidgetBalanceStatus status;
  final Map<String, AccountInfo>? data;
  final Object? error;

  TransferWidgetBalanceState copyWith({
    TransferWidgetBalanceStatus? status,
    Map<String, AccountInfo>? data,
    Object? error,
  }) {
    return TransferWidgetBalanceState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, data, error];
}
