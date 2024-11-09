part of 'send_payment_bloc.dart';

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

/// Holds the state for [SendPaymentBloc], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class SendPaymentState extends Equatable {
  /// Creates a new instance of [SendPaymentState].
  ///
  /// The [status] defaults to [SendPaymentStatus.initial] if not specified.
  const SendPaymentState({
    this.status = SendPaymentStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory SendPaymentState.fromJson(Map<String, dynamic> json) =>
      _$SendPaymentStateFromJson(json);

  /// The current status of the send payment operation.
  final SendPaymentStatus status;

  /// The response data from the send payment operation.
  ///
  /// Contains the `AccountBlockTemplate` representing the transaction.
  final AccountBlockTemplate? data;

  /// An object representing any error occurring during the payment operation.
  final Object? error;

  /// {@macro state_copy_with}
  SendPaymentState copyWith({
    SendPaymentStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return SendPaymentState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$SendPaymentStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
