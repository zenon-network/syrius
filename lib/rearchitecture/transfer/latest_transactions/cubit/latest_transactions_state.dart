part of 'latest_transactions_cubit.dart';

enum LatestTransactionsStatus {
  initial,
  loading,
  failure,
  success,
}

class LatestTransactionsState extends Equatable{

  const LatestTransactionsState({
    required this.status,
    this.data,
    this.error,
  });

  final LatestTransactionsStatus status;
  final List<AccountBlock>? data;
  final Object? error;

  LatestTransactionsState copyWith({
    LatestTransactionsStatus? status,
    List<AccountBlock>? data,
    Object? error,
  }) {
    return LatestTransactionsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, data, error];
}
