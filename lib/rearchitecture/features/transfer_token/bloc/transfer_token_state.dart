part of 'transfer_token_bloc.dart';

/// Base class for transfer-token states.
sealed class TransferTokenState extends Equatable {
  /// Creates a [TransferTokenState].
  const TransferTokenState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before an ownership transfer is requested.
final class TransferTokenInitial extends TransferTokenState {
  /// Creates a [TransferTokenInitial] state.
  const TransferTokenInitial();
}

/// Loading state while ownership is being transferred.
final class TransferTokenLoading extends TransferTokenState {
  /// Creates a [TransferTokenLoading] state.
  const TransferTokenLoading();
}

/// Success state emitted after ownership has been transferred.
final class TransferTokenDone extends TransferTokenState {
  /// Creates a [TransferTokenDone] state.
  const TransferTokenDone({required this.accountBlock});

  /// Account block returned after transferring ownership.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object?> get props => <Object?>[accountBlock];
}

/// Failure state emitted when transferring ownership fails.
final class TransferTokenFailure extends TransferTokenState {
  /// Creates a [TransferTokenFailure] state.
  const TransferTokenFailure({required this.exception});

  /// Error that caused the ownership transfer to fail.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
