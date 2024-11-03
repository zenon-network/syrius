part of 'send_payment_bloc.dart';

enum SendPaymentStatus { initial, loading, success, failure }

@JsonSerializable(explicitToJson: true)
class SendPaymentState extends Equatable {

  const SendPaymentState({
    this.status = SendPaymentStatus.initial,
    this.data,
    this.error,
  });

  factory SendPaymentState.fromJson(Map<String, dynamic> json) =>
      _$SendPaymentStateFromJson(json);

  final SendPaymentStatus status;
  final AccountBlockTemplate? data;
  final Object? error;

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

  Map<String, dynamic> toJson() => _$SendPaymentStateToJson(this);

  @override
  List<Object?> get props => [status, data, error];
}
