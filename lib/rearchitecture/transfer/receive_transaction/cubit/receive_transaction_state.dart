part of 'receive_transaction_cubit.dart';

/// Represents the possible statuses for receiving a transaction.
enum ReceiveTransactionStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the transaction is currently being processed.
  loading,

  /// Indicates that an error occurred during the transaction process.
  failure,

  /// Indicates that the transaction was successfully received.
  success,
}

/// Holds the state for receiving a transaction, including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class ReceiveTransactionState extends Equatable {
  /// Creates a new instance of [ReceiveTransactionState].
  ///
  /// The [status] defaults to [ReceiveTransactionStatus.initial].
  const ReceiveTransactionState({
    this.status = ReceiveTransactionStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory ReceiveTransactionState.fromJson(Map<String, dynamic> json) =>
      _$ReceiveTransactionStateFromJson(json);

  /// The current status of the receive transaction operation.
  final ReceiveTransactionStatus status;

  /// The [AccountBlockTemplate] representing the transaction data.
  ///
  /// It is populated when the [status] is [ReceiveTransactionStatus.success].
  final AccountBlockTemplate? data;

  /// An object representing any error occurring during the transaction process.
  ///
  /// Populated when [status] is [ReceiveTransactionStatus.failure].
  final Object? error;

  /// {@macro state_copy_with}
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

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$ReceiveTransactionStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
