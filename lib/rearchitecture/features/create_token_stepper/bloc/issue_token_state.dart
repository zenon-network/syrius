part of 'issue_token_bloc.dart';

/// Base class for issue token states.
sealed class IssueTokenState extends Equatable {
  /// Creates an [IssueTokenState].
  const IssueTokenState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before issuing starts.
final class IssueTokenInitial extends IssueTokenState {
  /// Creates an [IssueTokenInitial] state.
  const IssueTokenInitial();
}

/// Loading state while the token is being issued.
final class IssueTokenLoading extends IssueTokenState {
  /// Creates an [IssueTokenLoading] state.
  const IssueTokenLoading();
}

/// Success state emitted after the token has been issued.
final class IssueTokenDone extends IssueTokenState {
  /// Creates an [IssueTokenDone] state.
  const IssueTokenDone({required this.accountBlock});

  /// Account block returned after issuing the token.
  final AccountBlockTemplate accountBlock;

  @override
  List<Object?> get props => <Object?>[accountBlock];
}

/// Failure state emitted when issuing fails.
final class IssueTokenFailure extends IssueTokenState {
  /// Creates an [IssueTokenFailure] state.
  const IssueTokenFailure({required this.exception});

  /// The error that caused token issuing to fail.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
