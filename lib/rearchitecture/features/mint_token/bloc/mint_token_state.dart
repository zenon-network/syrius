part of 'mint_token_bloc.dart';

/// Base class for mint-token states.
sealed class MintTokenState extends Equatable {
  /// Creates a [MintTokenState].
  const MintTokenState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before minting starts.
final class MintTokenInitial extends MintTokenState {
  /// Creates a [MintTokenInitial] state.
  const MintTokenInitial();
}

/// Loading state while the token is being minted.
final class MintTokenLoading extends MintTokenState {
  /// Creates a [MintTokenLoading] state.
  const MintTokenLoading();
}

/// Success state emitted after the token has been minted.
final class MintTokenDone extends MintTokenState {
  /// Creates a [MintTokenDone] state.
  const MintTokenDone({required this.accountBlock});

  /// Account block returned after minting the token.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object?> get props => <Object?>[accountBlock];
}

/// Failure state emitted when minting fails.
final class MintTokenFailure extends MintTokenState {
  /// Creates a [MintTokenFailure] state.
  const MintTokenFailure({required this.exception});

  /// Error that caused minting to fail.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
