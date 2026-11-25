import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

void main() {
  group('LockBloc', () {
    test('initial state is initial with sequence 0', () {
      final LockBloc bloc = LockBloc(currentPageProvider: () => Tabs.dashboard);
      addTearDown(bloc.close);

      expect(bloc.state, const WalletLockState());
    });

    blocTest<LockBloc, WalletLockState>(
      'emits incrementing sequences for repeated timer resets when unlocked',
      build: () => LockBloc(currentPageProvider: () => Tabs.dashboard),
      act: (LockBloc bloc) => bloc
        ..add(const LockTimerResetRequested())
        ..add(const LockTimerResetRequested()),
      expect: () => const <WalletLockState>[
        WalletLockState(action: LockAction.resetTimer, sequence: 1),
        WalletLockState(action: LockAction.resetTimer, sequence: 2),
      ],
    );

    blocTest<LockBloc, WalletLockState>(
      'ignores LockTimerResetRequested while on the lock tab',
      build: () => LockBloc(currentPageProvider: () => Tabs.lock),
      act: (LockBloc bloc) => bloc.add(const LockTimerResetRequested()),
      expect: () => const <WalletLockState>[],
    );

    blocTest<LockBloc, WalletLockState>(
      'emits all lock navigation and countdown actions in order',
      build: () => LockBloc(currentPageProvider: () => Tabs.lock),
      act: (LockBloc bloc) => bloc
        ..add(const LockCountDownRequested())
        ..add(const LockNavigateToDashboardRequested())
        ..add(const LockNavigateToLockRequested())
        ..add(const LockNavigateToPreviousTabRequested()),
      expect: () => const <WalletLockState>[
        WalletLockState(action: LockAction.countDown, sequence: 1),
        WalletLockState(action: LockAction.navigateToDashboard, sequence: 2),
        WalletLockState(action: LockAction.navigateToLock, sequence: 3),
        WalletLockState(action: LockAction.navigateToPreviousTab, sequence: 4),
      ],
    );
  });
}
