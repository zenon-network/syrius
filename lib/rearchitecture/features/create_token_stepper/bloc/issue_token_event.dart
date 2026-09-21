part of 'issue_token_bloc.dart';

/// Base class for issue token events.
sealed class IssueTokenEvent extends Equatable {
  /// Creates an [IssueTokenEvent].
  const IssueTokenEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests issuing a new token.
final class IssueTokenRequested extends IssueTokenEvent {
  /// Creates an [IssueTokenRequested] event.
  const IssueTokenRequested({required this.tokenData});

  /// Token data entered in the create-token stepper.
  final NewTokenData tokenData;

  @override
  List<Object?> get props => <Object?>[tokenData];
}
