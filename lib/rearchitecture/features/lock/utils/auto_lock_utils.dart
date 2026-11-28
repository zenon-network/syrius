/// Returns whether an auto-lock inactivity timer tick should lock the wallet.
///
/// Auto-lock is suppressed when any incoming HTLC swap is still active, when
/// the wallet is already locked, or when the inactivity timer is not active.
bool shouldAutoLockOnTimer({
  required bool hasActiveIncomingSwaps,
  required bool isLocked,
  required bool timerActive,
}) {
  return !hasActiveIncomingSwaps && !isLocked && timerActive;
}
