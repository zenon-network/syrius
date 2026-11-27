/// Categories of notifications stored and displayed by the wallet.
enum NotificationType {
  /// Notification for an outgoing payment transaction.
  paymentSent,

  /// Notification for a wallet or network error.
  error,

  /// Notification indicating that staking was deactivated.
  stakingDeactivated,

  /// Notification for an incoming payment transaction.
  paymentReceived,

  /// Notification that the auto-lock interval setting changed.
  autoLockIntervalChanged,

  /// Notification that content was copied to the clipboard.
  copiedToClipboard,

  /// Notification for a received staking, pillar, or sentinel reward.
  rewardReceived,

  /// Notification that the auto-erase attempt limit changed.
  autoEraseNumAttemptsChanged,

  /// Notification that plasma generation is in progress.
  generatingPlasma,

  /// Notification for a token burn operation.
  burnToken,

  /// Notification that a token was added to favourites.
  addedTokenFavourite,

  /// Notification that a token was removed from favourites.
  removedTokenFavourite,

  /// Notification that the wallet was reset.
  resetWallet,

  /// Notification that the active node connection changed.
  changedNode,

  /// Notification for a deletion action.
  delete,

  /// Notification for a user confirmation event.
  confirm,
}
