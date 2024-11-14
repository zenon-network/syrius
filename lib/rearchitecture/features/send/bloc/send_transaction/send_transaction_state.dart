part of 'send_transaction_bloc.dart';

/// Represents the possible statuses of the send payment operation.
enum SendPaymentStatus {
  /// The initial state before any payment action has been taken.
  initial,

  /// Indicates that the payment process is currently in progress.
  loading,

  /// Indicates that the payment was successfully processed.
  success,

  /// Indicates that an error occurred during the payment process.
  failure
}

/// Holds the state for [SendTransactionBloc], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class SendTransactionState extends Equatable {
  /// Creates a new instance of [SendTransactionState].
  ///
  /// The [status] defaults to [SendPaymentStatus.initial] if not specified.
  const SendTransactionState({
    this.status = SendPaymentStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory SendTransactionState.fromJson(Map<String, dynamic> json) =>
      _$SendTransactionStateFromJson(json);

  /// The current status of the send payment operation.
  final SendPaymentStatus status;

  /// The response data from the send payment operation.
  ///
  /// Contains the `AccountBlockTemplate` representing the transaction.
  final AccountBlockTemplate? data;

  /// An object representing any error occurring during the payment operation.
  final SyriusException? error;

  /// {@macro state_copy_with}
  SendTransactionState copyWith({
    SendPaymentStatus? status,
    AccountBlockTemplate? data,
    SyriusException? error,
  }) {
    return SendTransactionState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$SendTransactionStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
