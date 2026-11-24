part of 'reclaim_deposit_bloc.dart';

/// Base class for reclaim-deposit states.
sealed class ReclaimDepositState extends Equatable {
  /// Creates a [ReclaimDepositState].
  const ReclaimDepositState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before a reclaim is requested.
final class ReclaimDepositInitial extends ReclaimDepositState {
  /// Creates a [ReclaimDepositInitial] state.
  const ReclaimDepositInitial();
}

/// Loading state while the reclaim transaction is being submitted.
final class ReclaimDepositLoading extends ReclaimDepositState {
  /// Creates a [ReclaimDepositLoading] state.
  const ReclaimDepositLoading();
}

/// Success state emitted after the reclaim transaction is submitted.
final class ReclaimDepositDone extends ReclaimDepositState {
  /// Creates a [ReclaimDepositDone] state.
  const ReclaimDepositDone({required this.block});

  /// The submitted reclaim block.
  final AccountBlockTemplate block;

  @override
  List<Object> get props => <Object>[block];
}

/// Failure state emitted when the deposit cannot be reclaimed.
final class ReclaimDepositFailure extends ReclaimDepositState {
  /// Creates a [ReclaimDepositFailure] state.
  const ReclaimDepositFailure({required this.exception});

  /// Error that prevented the deposit from being reclaimed.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}
