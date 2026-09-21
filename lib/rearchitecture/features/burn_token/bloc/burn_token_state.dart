part of 'burn_token_bloc.dart';

/// Base class for burn-token states.
sealed class BurnTokenState extends Equatable {
  /// Creates a [BurnTokenState].
  const BurnTokenState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before a burn is requested.
final class BurnTokenInitial extends BurnTokenState {
  /// Creates a [BurnTokenInitial] state.
  const BurnTokenInitial();
}

/// Loading state while the token is being burned.
final class BurnTokenLoading extends BurnTokenState {
  /// Creates a [BurnTokenLoading] state.
  const BurnTokenLoading();
}

/// Success state emitted after the token has been burned.
final class BurnTokenDone extends BurnTokenState {
  /// Creates a [BurnTokenDone] state.
  const BurnTokenDone({required this.accountBlock});

  /// Account block returned after burning the token.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object?> get props => <Object?>[accountBlock];
}

/// Failure state emitted when burning fails.
final class BurnTokenFailure extends BurnTokenState {
  /// Creates a [BurnTokenFailure] state.
  const BurnTokenFailure({required this.exception});

  /// Error that caused the burn to fail.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
