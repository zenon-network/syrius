part of 'send_payment_bloc.dart';

enum SendPaymentStatus { initial, loading, success, failure }

class SendPaymentState extends Equatable {

  const SendPaymentState({
    required this.status,
    this.data,
    this.error,
  });

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

  @override
  List<Object?> get props => [status, data, error];
}
