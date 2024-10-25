part of 'receive_transaction_cubit.dart';

enum ReceiveTransactionStatus {
  initial,
  loading,
  failure,
  success,
}

class ReceiveTransactionState extends Equatable{

  const ReceiveTransactionState({
    required this.status,
    this.data,
    this.error,
  });

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

  @override
  List<Object?> get props => [status, data, error];
}
