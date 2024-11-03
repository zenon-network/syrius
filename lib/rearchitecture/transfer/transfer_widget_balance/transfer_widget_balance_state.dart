part of 'transfer_widget_balance_bloc.dart';

enum TransferWidgetBalanceStatus { initial, loading, success, failure }

@JsonSerializable(explicitToJson: true)
class TransferWidgetBalanceState extends Equatable {

  const TransferWidgetBalanceState({
    this.status = TransferWidgetBalanceStatus.initial,
    this.data,
    this.error,
  });

  factory TransferWidgetBalanceState.fromJson(Map<String, dynamic> json) =>
      _$TransferWidgetBalanceStateFromJson(json);

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

  Map<String, dynamic> toJson() => _$TransferWidgetBalanceStateToJson(this);

  @override
  List<Object?> get props => [status, data, error];
}
