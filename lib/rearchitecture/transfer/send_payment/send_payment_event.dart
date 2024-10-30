part of 'send_payment_bloc.dart';

sealed class SendPaymentEvent extends Equatable {}

class SendTransfer extends SendPaymentEvent {

  SendTransfer({
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.token,
    this.data,
  });
  final String fromAddress;
  final String toAddress;
  final BigInt amount;
  final List<int>? data;
  final Token token;

  @override
  List<Object?> get props => [fromAddress, toAddress, amount, token, data];
}

class SendTransferWithBlock extends SendPaymentEvent {

  SendTransferWithBlock({
    required this.block,
    required this.fromAddress,
  });
  final AccountBlockTemplate block;
  final String fromAddress;

  @override
  List<Object?> get props => [block, fromAddress];
}
