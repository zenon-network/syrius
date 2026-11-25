part of 'submit_donation_bloc.dart';

/// Base state for [SubmitDonationBloc].
sealed class SubmitDonationState extends Equatable {
  /// Creates a [SubmitDonationState].
  const SubmitDonationState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before a donation is submitted.
final class SubmitDonationInitial extends SubmitDonationState {
  /// Creates a [SubmitDonationInitial] state.
  const SubmitDonationInitial();
}

/// State emitted while submitting donation transaction(s).
final class SubmitDonationLoading extends SubmitDonationState {
  /// Creates a [SubmitDonationLoading] state.
  const SubmitDonationLoading();
}

/// State emitted after all requested donation transaction(s) succeed.
final class SubmitDonationDone extends SubmitDonationState {
  /// Creates a [SubmitDonationDone] state.
  const SubmitDonationDone({required this.blocks});

  /// Published account blocks for the submitted donation(s).
  final List<AccountBlockTemplate> blocks;

  @override
  List<Object?> get props => <Object?>[blocks];
}

/// State emitted when submitting a donation fails.
final class SubmitDonationFailure extends SubmitDonationState {
  /// Creates a [SubmitDonationFailure] state.
  const SubmitDonationFailure({
    required this.exception,
    this.sentBlocks = const <AccountBlockTemplate>[],
    this.znnSubmitted = false,
  });

  /// Failure describing why the donation did not complete.
  final SyriusException exception;

  /// Account blocks that were already published before the failure occurred.
  final List<AccountBlockTemplate> sentBlocks;

  /// Whether the ZNN donation block was already published before a subsequent
  /// QSR donation failure.
  final bool znnSubmitted;

  @override
  List<Object?> get props => <Object?>[exception, sentBlocks, znnSubmitted];
}
