part of 'accelerator_balance_bloc.dart';

/// Base state for [AcceleratorBalanceBloc].
sealed class AcceleratorBalanceState extends Equatable {
  /// Creates an [AcceleratorBalanceState].
  const AcceleratorBalanceState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before the Accelerator balance is loaded.
final class AcceleratorBalanceInitial extends AcceleratorBalanceState {
  /// Creates an [AcceleratorBalanceInitial] state.
  const AcceleratorBalanceInitial();
}

/// State emitted while loading the Accelerator balance.
final class AcceleratorBalanceLoading extends AcceleratorBalanceState {
  /// Creates an [AcceleratorBalanceLoading] state.
  const AcceleratorBalanceLoading();
}

/// State emitted when the Accelerator balance is loaded and non-empty.
final class AcceleratorBalancePopulated extends AcceleratorBalanceState {
  /// Creates an [AcceleratorBalancePopulated] state.
  const AcceleratorBalancePopulated({required this.accountInfo});

  /// Account balance information for the Accelerator contract address.
  final AccountInfo accountInfo;

  @override
  List<Object?> get props => <Object?>[accountInfo];
}

/// State emitted when loading the Accelerator balance fails or the fund is
/// empty.
final class AcceleratorBalanceFailure extends AcceleratorBalanceState {
  /// Creates an [AcceleratorBalanceFailure] state.
  const AcceleratorBalanceFailure({required this.exception});

  /// Failure describing why the balance could not be shown.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
