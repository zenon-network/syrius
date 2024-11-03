part of 'receive_transaction_cubit.dart';

enum ReceiveTransactionStatus {
  initial,
  loading,
  failure,
  success,
}

@JsonSerializable(explicitToJson: true)
class ReceiveTransactionState extends Equatable{

  const ReceiveTransactionState({
    this.status = ReceiveTransactionStatus.initial,
    this.data,
    this.error,
  });

  factory ReceiveTransactionState.fromJson(Map<String, dynamic> json) =>
      _$ReceiveTransactionStateFromJson(json);

  final ReceiveTransactionStatus status;
  final AccountBlockTemplate? data;
  final Object? error;

  ReceiveTransactionState copyWith({
    ReceiveTransactionStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return ReceiveTransactionState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => _$ReceiveTransactionStateToJson(this);

  @override
  List<Object?> get props => [status, data, error];
}
