part of 'send_payment_bloc.dart';

/// The base class for events in `SendPaymentBloc`.
sealed class SendPaymentEvent extends Equatable {}

/// Event to initiate sending a transfer.
class SendTransfer extends SendPaymentEvent {
  /// Creates a `SendTransfer` event.
  SendTransfer({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.token,
    this.data,
  });

  /// The address from which the payment is sent.
  final String fromAddress;

  /// The address to which the payment is sent.
  final String toAddress;

  /// The amount to be transferred.
  final BigInt amount;

  /// Optional data associated with the transfer.
  final List<int>? data;

  /// The token being transferred.
  final Token token;

  @override
  List<Object?> get props =>
      <Object?>[fromAddress, toAddress, amount, token, data];
}

/// Event to initiate sending a transfer using an existing account block.
class SendTransferWithBlock extends SendPaymentEvent {
  /// Creates a `SendTransferWithBlock` event.
  SendTransferWithBlock({
    required this.block,
    required this.fromAddress,
  });

  /// The account block template representing the transfer.
  final AccountBlockTemplate block;

  /// The address from which the payment is sent.
  final String fromAddress;

  @override
  List<Object?> get props => <Object?>[block, fromAddress];
}
