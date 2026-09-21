part of 'transfer_token_bloc.dart';

/// Base class for transfer-token events.
sealed class TransferTokenEvent extends Equatable {
  /// Creates a [TransferTokenEvent].
  const TransferTokenEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests transferring ownership of a token to a new address.
final class TransferTokenRequested extends TransferTokenEvent {
  /// Creates a [TransferTokenRequested] event.
  const TransferTokenRequested({
    required this.newOwnerAddress,
    required this.token,
  });

  /// Address that will become the token owner.
  final Address newOwnerAddress;

  /// Token whose ownership will be transferred.
  final Token token;

  @override
  List<Object?> get props => <Object?>[newOwnerAddress, token];
}
