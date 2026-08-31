part of 'burn_token_bloc.dart';

/// Base class for burn-token events.
sealed class BurnTokenEvent extends Equatable {
  /// Creates a [BurnTokenEvent].
  const BurnTokenEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests burning an amount of a token.
final class BurnTokenRequested extends BurnTokenEvent {
  /// Creates a [BurnTokenRequested] event.
  const BurnTokenRequested({
    required this.amount,
    required this.token,
  });

  /// Amount to burn in the token's smallest unit.
  final BigInt amount;

  /// Token to burn.
  final Token token;

  @override
  List<Object?> get props => <Object?>[amount, token];
}
