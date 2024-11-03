part of 'pending_transactions_cubit.dart';

enum PendingTransactionsStatus {
  initial,
  loading,
  failure,
  success,
}

@JsonSerializable(explicitToJson: true)
class PendingTransactionsState extends Equatable {

  const PendingTransactionsState({
    this.status = PendingTransactionsStatus.initial,
    this.data,
    this.error,
  });

  factory PendingTransactionsState.fromJson(Map<String, dynamic> json) =>
      _$PendingTransactionsStateFromJson(json);

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

  Map<String, dynamic> toJson() => _$PendingTransactionsStateToJson(this);

  @override
  List<Object?> get props => [status, data, error];
}
