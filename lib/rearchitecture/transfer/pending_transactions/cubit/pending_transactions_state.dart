part of 'pending_transactions_cubit.dart';

enum PendingTransactionsStatus {
  initial,
  loading,
  failure,
  success,
}

class PendingTransactionsState extends Equatable {

  const PendingTransactionsState({
    required this.status,
    this.data,
    this.error,
  });

  final PendingTransactionsStatus status;
  final List<AccountBlock>? data;
  final Object? error;

  PendingTransactionsState copyWith({
    PendingTransactionsStatus? status,
    List<AccountBlock>? data,
    Object? error,
  }) {
    return PendingTransactionsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, data, error];
}
