import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

part 'lock_event.dart';
part 'lock_state.dart';

/// BLoC coordinating wallet lock navigation and auto-lock timer resets.
class LockBloc extends Bloc<LockEvent, WalletLockState> {
  /// Creates a [LockBloc].
  LockBloc({Tabs? Function()? currentPageProvider})
    : _currentPageProvider = currentPageProvider ?? _defaultCurrentPage,
      super(const WalletLockState()) {
    on<LockCountDownRequested>(_onCountDownRequested);
    on<LockNavigateToLockRequested>(_onNavigateToLockRequested);
    on<LockTimerResetRequested>(_onTimerResetRequested);
    on<LockNavigateToDashboardRequested>(_onNavigateToDashboardRequested);
    on<LockNavigateToPreviousTabRequested>(_onNavigateToPreviousTabRequested);
  }

  final Tabs? Function() _currentPageProvider;

  void _onCountDownRequested(
    LockCountDownRequested event,
    Emitter<WalletLockState> emit,
  ) {
    emit(
      WalletLockState(
        action: LockAction.countDown,
        sequence: state.sequence + 1,
      ),
    );
  }

  void _onNavigateToLockRequested(
    LockNavigateToLockRequested event,
    Emitter<WalletLockState> emit,
  ) {
    emit(
      WalletLockState(
        action: LockAction.navigateToLock,
        sequence: state.sequence + 1,
      ),
    );
  }

  void _onTimerResetRequested(
    LockTimerResetRequested event,
    Emitter<WalletLockState> emit,
  ) {
    if (_currentPageProvider() == Tabs.lock) {
      return;
    }
    emit(
      WalletLockState(
        action: LockAction.resetTimer,
        sequence: state.sequence + 1,
      ),
    );
  }

  void _onNavigateToDashboardRequested(
    LockNavigateToDashboardRequested event,
    Emitter<WalletLockState> emit,
  ) {
    emit(
      WalletLockState(
        action: LockAction.navigateToDashboard,
        sequence: state.sequence + 1,
      ),
    );
  }

  void _onNavigateToPreviousTabRequested(
    LockNavigateToPreviousTabRequested event,
    Emitter<WalletLockState> emit,
  ) {
    emit(
      WalletLockState(
        action: LockAction.navigateToPreviousTab,
        sequence: state.sequence + 1,
      ),
    );
  }

  static Tabs? _defaultCurrentPage() => kCurrentPage;
}
