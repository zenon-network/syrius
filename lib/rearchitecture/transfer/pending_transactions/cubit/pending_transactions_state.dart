part of 'pending_transactions_cubit.dart';

/// Represents the various statuses of pending transactions.
enum PendingTransactionsStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for pending transactions, including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class PendingTransactionsState extends Equatable {
  /// Creates a new instance of [PendingTransactionsState].
  ///
  /// The [status] defaults to [PendingTransactionsStatus.initial].
  const PendingTransactionsState({
    this.status = PendingTransactionsStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory PendingTransactionsState.fromJson(Map<String, dynamic> json) =>
      _$PendingTransactionsStateFromJson(json);

  /// The current status of the pending transactions operation.
  final PendingTransactionsStatus status;

  /// The list of [AccountBlock] instances representing pending transactions.
  ///
  /// It is populated when [status] is [PendingTransactionsStatus.success].
  final List<AccountBlock>? data;

  /// An object representing any error that occurred during data fetching.
  ///
  /// Populated when the [status] is [PendingTransactionsStatus.failure].
  final Object? error;

  /// {@macro state_copy_with}
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

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PendingTransactionsStateToJson(this);

  /// {@macro equatable_props}
  @override
  List<Object?> get props => <Object?>[status, data, error];
}
