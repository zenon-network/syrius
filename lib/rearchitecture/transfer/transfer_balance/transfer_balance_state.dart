part of 'transfer_balance_bloc.dart';

enum TransferBalanceStatus { initial, loading, success, failure }

@JsonSerializable(explicitToJson: true)
class TransferBalanceState extends Equatable {

  const TransferBalanceState({
    this.status = TransferBalanceStatus.initial,
    this.data,
    this.error,
  });

  factory TransferBalanceState.fromJson(Map<String, dynamic> json) =>
      _$TransferBalanceStateFromJson(json);

  final TransferBalanceStatus status;
  final Map<String, AccountInfo>? data;
  final Object? error;

  TransferBalanceState copyWith({
    TransferBalanceStatus? status,
    Map<String, AccountInfo>? data,
    Object? error,
  }) {
    return TransferBalanceState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => _$TransferBalanceStateToJson(this);

  @override
  List<Object?> get props => [status, data, error];
}
