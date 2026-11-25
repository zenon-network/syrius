part of 'accelerator_balance_bloc.dart';

/// Base event for [AcceleratorBalanceBloc].
sealed class AcceleratorBalanceEvent extends Equatable {
  /// Creates an [AcceleratorBalanceEvent].
  const AcceleratorBalanceEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests the current balance of the Accelerator embedded contract address.
final class AcceleratorBalanceRequested extends AcceleratorBalanceEvent {
  /// Creates an [AcceleratorBalanceRequested] event.
  const AcceleratorBalanceRequested();
}
