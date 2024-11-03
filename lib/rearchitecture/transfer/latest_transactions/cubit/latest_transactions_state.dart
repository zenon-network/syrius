part of 'latest_transactions_cubit.dart';

enum LatestTransactionsStatus {
  initial,
  loading,
  failure,
  success,
}

@JsonSerializable(explicitToJson: true)
class LatestTransactionsState extends Equatable{

  const LatestTransactionsState({
    this.status = LatestTransactionsStatus.initial,
    this.data,
    this.error,
  });

  factory LatestTransactionsState.fromJson(Map<String, dynamic> json) =>
      _$LatestTransactionsStateFromJson(json);

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

  Map<String, dynamic> toJson() => _$LatestTransactionsStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
