part of 'mint_token_bloc.dart';

/// Base class for mint-token events.
sealed class MintTokenEvent extends Equatable {
  /// Creates a [MintTokenEvent].
  const MintTokenEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests minting an amount of a token to a beneficiary address.
final class MintTokenRequested extends MintTokenEvent {
  /// Creates a [MintTokenRequested] event.
  const MintTokenRequested({
    required this.amount,
    required this.beneficiaryAddress,
    required this.token,
  });

  /// Amount to mint in the token's smallest unit.
  final BigInt amount;

  /// Address that will receive the minted tokens.
  final Address beneficiaryAddress;

  /// Token to mint.
  final Token token;

  @override
  List<Object?> get props => <Object?>[amount, beneficiaryAddress, token];
}
