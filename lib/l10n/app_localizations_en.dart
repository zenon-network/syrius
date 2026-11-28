// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get abstain => 'Abstain';

  @override
  String get acceleratorAvailableBalance => 'Accelerator available balance';

  @override
  String get acceleratorDonations => 'Accelerator Donations';

  @override
  String get acceleratorFundEmpty => 'Accelerator fund empty';

  @override
  String get acceleratorStats => 'Accelerator Stats';

  @override
  String get accepted => 'Accepted';

  @override
  String get accessWallet => 'Access wallet';

  @override
  String get accountChainHeight => 'Account-chain height';

  @override
  String get accountChainStats => 'Account-chain Stats';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get active => 'Active';

  @override
  String get activePillars => 'Active Pillars';

  @override
  String get activeSentinels => 'Active Sentinels';

  @override
  String get activeSwap => 'Active swap';

  @override
  String addAddressesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count addresses',
      one: 'Add 1 address',
    );
    return '$_temp0';
  }

  @override
  String get addNode => 'Add node';

  @override
  String get address => 'Address';

  @override
  String addressNotInWalletList(String address) {
    return 'Address $address is not present in the wallet address list.';
  }

  @override
  String addressNumber(int index) {
    return 'Address $index';
  }

  @override
  String get addressOwnsOrProducesNoPillar =>
      'This address owns or produces no pillar';

  @override
  String get addressSearchDescription =>
      'Addresses can be searched by label - \"Address 1\" - and by hex value - \"z1qxemdeddedxt0kenxxxxxxxxxxxxxxxxh9amk0\"';

  @override
  String get addressToCollectRewards =>
      'The address that will be able to collect the Pillar rewards';

  @override
  String get addressToProduceMomentums =>
      'The address that will produce momentums, get it from znn-controller';

  @override
  String get addresses => 'Addresses';

  @override
  String get allDonatedFundsGoToAccelerator =>
      'All donated funds go directly into the Accelerator address';

  @override
  String get allWalletDataErasedPermanently =>
      'All your wallet data will be erased permanently. Make sure you have a backup of your mnemonic or Seed Vault & Seed Vault Key before you proceed with erasing the wallet';

  @override
  String get alphanetChainIdentifier => 'Alphanet chain identifier';

  @override
  String get alreadyVoted => 'Already voted';

  @override
  String get amount => 'Amount';

  @override
  String areYouSureTranfer(Object amount, Object recipient, Object symbol) {
    return 'Are you sure you want to transfer $amount $symbol to $recipient ?';
  }

  @override
  String get asset => 'Asset';

  @override
  String attemptsLeft(int count) {
    return '$count attempts left';
  }

  @override
  String get autoEraseLimitChanged =>
      'Auto-erase attempts limit successfully changed';

  @override
  String autoEraseLimitNowAttempts(String attempts) {
    return 'The auto-erase limit has now $attempts attempt(s)';
  }

  @override
  String get autoEraseWallet => 'Auto-erase wallet';

  @override
  String get autoLockWallet => 'Auto-lock wallet';

  @override
  String get autoReceiver => 'Auto-receiver';

  @override
  String autoReceiverPreferenceStatus(String status) {
    return 'Auto-receiver preference was $status';
  }

  @override
  String autoReceiverStatus(String status) {
    return 'Auto-receiver $status';
  }

  @override
  String get automaticallyReceiveTransactions =>
      'Automatically receive transactions';

  @override
  String get available => 'Available';

  @override
  String availableBalanceMustBeAtLeast(String minValue) {
    return 'Your available balance must be at least $minValue';
  }

  @override
  String get backedUpSeedInSafeLocation =>
      'I have backed up my seed in a safe location';

  @override
  String get backup => 'Backup';

  @override
  String get backupSeedEncryptedOrClearText =>
      'Backup your seed using the syrius standard format JSON (encrypted, recommended) or show it on the screen (clear text, not recommended)';

  @override
  String get backupWallet => 'Backup wallet';

  @override
  String get balance => 'Balance';

  @override
  String get balanceUnavailableForAddress =>
      'Balance is unavailable for the selected address';

  @override
  String get beneficiaryAddress => 'Beneficiary address';

  @override
  String get blockHash => 'Block hash';

  @override
  String get burn => 'Burn';

  @override
  String burnTokenIssueFee(Object amount, Object symbol) {
    return 'You will need to burn $amount $symbol to issue a token';
  }

  @override
  String get burnableToken => 'Burnable by any holder';

  @override
  String get cacheDeletionFailed => 'Cache deletion failed';

  @override
  String get cameraQrScanner => 'Camera QR Scanner';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelPlasmaConfirmation =>
      'Are you sure you want to cancel the Plasma fusion?';

  @override
  String get cannotJoinOwnSwap => 'Cannot join a swap that you have started.';

  @override
  String get cannotJoinSwapExpiresTooSoon =>
      'Cannot join swap. The swap will expire too soon for a safe swap.';

  @override
  String get cannotReuseAddressForSentinel =>
      'If this address previously revoked a Sentinel, it cannot create a new Sentinel again. Use a different address before depositing QSR.';

  @override
  String get chainIdentifierMismatch => 'Chain identifier mismatch';

  @override
  String chainIdentifierMismatchDetails(int clientChainId, int nodeChainId) {
    return 'Chain identifier mismatch\nClient chain identifier: $clientChainId\nNode chain identifier: $nodeChainId';
  }

  @override
  String get chainIdentifierPreventsReplayAttacks =>
      'The chain identifier is used in transaction signing to prevent replay attacks';

  @override
  String get change => 'Change';

  @override
  String get changePassword => 'Change password';

  @override
  String get changeWalletPassword => 'Change wallet password';

  @override
  String get changeWalletSecurityParameters =>
      'Change the security parameters of the wallet';

  @override
  String changedClientChainIdentifier(int chainId) {
    return 'Successfully changed client chain identifier to $chainId';
  }

  @override
  String changedClientChainIdentifierFromTo(int oldChainId, int newChainId) {
    return 'Successfully changed client chain identifier from $oldChainId to $newChainId';
  }

  @override
  String get checkPillarStatus => ' to check the Pillar status';

  @override
  String get checkSentinelStatus => ' to check the Sentinel status';

  @override
  String get checkUpdate => 'Check update';

  @override
  String get checkUpdatesForSyriusWallet =>
      'Check updates for the Syrius wallet';

  @override
  String get chooseYourDevice => 'Choose your device';

  @override
  String get clearAllNotifications => 'Clear all notifications';

  @override
  String get clickToAddToFavorites => 'Click to add to favorites';

  @override
  String get clickToBrowseOrDragAndDropFile =>
      'Click to browse or drag and drop a file';

  @override
  String get clickToRemoveFromFavorites => 'Click to remove from favorites';

  @override
  String clientAndNodeChainIdentifiers(int clientChainId, int nodeChainId) {
    return 'Client chain identifier: $clientChainId\nNode chain identifier: $nodeChainId';
  }

  @override
  String get clientChainIdentifier => 'Client chain identifier';

  @override
  String get clientChainIdentifierSelection =>
      'Client chain identifier selection';

  @override
  String get clientHostname => 'Client hostname';

  @override
  String get clientLocalIpAddress => 'Client local IP address';

  @override
  String get clientNumberOfProcessors => 'Client number of processors';

  @override
  String get clientOperatingSystem => 'Client operating system';

  @override
  String get clientOperatingSystemVersion => 'Client operating system version';

  @override
  String clipboardWatcherPreferenceStatus(String status) {
    return 'Clipboard watcher preference was $status';
  }

  @override
  String clipboardWatcherStatus(String status) {
    return 'Clipboard watcher $status';
  }

  @override
  String get coin => 'Coin';

  @override
  String get collect => 'Collect';

  @override
  String get collectPillarRewards => 'Collect Pillar rewards';

  @override
  String get collectSentinelRewards => 'Collect Sentinel rewards';

  @override
  String get collectStakingRewards => 'Collect staking rewards';

  @override
  String get community => 'Community';

  @override
  String get communityNode => 'Community Node';

  @override
  String get completed => 'Completed';

  @override
  String get confirm => 'Confirm';

  @override
  String confirmAddressAccountIndex(int index) {
    return 'Confirm address for account index: $index';
  }

  @override
  String get confirmNode => 'Confirm node';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmScale => 'Confirm scale';

  @override
  String get confirmTheme => 'Confirm theme';

  @override
  String get confirmYourSeed => 'Confirm your seed';

  @override
  String get connect => 'Connect';

  @override
  String get connectAndUnlockYourDevice =>
      'Please connect and unlock your device';

  @override
  String connectionCouldNotBeEstablished(String node) {
    return 'Connection could not be established to $node';
  }

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String consumeZnnToSubmitProject(String amount, String symbol) {
    return 'Consume $amount $symbol to submit the project';
  }

  @override
  String get continueText => 'Continue';

  @override
  String get copyDepositId => 'Copy deposit ID';

  @override
  String couldNotReconnectToNode(String node) {
    return 'Could not reconnect to $node';
  }

  @override
  String couldNotSend(Object amount, Object recipient, Object symbol) {
    return 'Couldn\'t send $amount $symbol to $recipient';
  }

  @override
  String get counterpartyAddress => 'Counterparty address';

  @override
  String get counterpartyDepositId => 'Counterparty deposit ID';

  @override
  String counterpartyTimeToCompleteSwap(int hours) {
    return 'The counterparty will have <highlight>~$hours hour</highlight> to complete the swap.';
  }

  @override
  String get create => 'Create';

  @override
  String get createAnotherPhase => 'Create another phase';

  @override
  String get createAnotherProject => 'Create another project';

  @override
  String get createAnotherToken => 'Create another Token';

  @override
  String get createPhase => 'Create phase';

  @override
  String get createPhaseForYourProject =>
      'Create a phase for your project. The project can be divided into several phases. You will unlock the funds if you get enough votes from the Pillars.';

  @override
  String get createPillarDescription =>
      'Start the process of deploying a Pillar Node in the network';

  @override
  String get createPillarTitle => 'Create Pillar';

  @override
  String get createProject => 'Create project';

  @override
  String get createSentinelDescription =>
      'Start the process of deploying a Sentinel Node in the network';

  @override
  String get createStake => 'create stake';

  @override
  String createStakeDescription(Object kQsrCoinSymbol, Object kZnnCoinSymbol) {
    return 'This card displays information about staking per wallet address. Choose the duration and the amount in $kZnnCoinSymbol for staking in order to receive $kQsrCoinSymbol';
  }

  @override
  String get createStakeTitle => 'Create Stake';

  @override
  String get createToken => 'Create Token';

  @override
  String get createTokenDescription =>
      'Create a token following the ZTS specification';

  @override
  String get createTokenTitle => 'Create Token';

  @override
  String get createWallet => 'Create wallet';

  @override
  String get createWalletPassword => 'Create a wallet password';

  @override
  String createdWithDate(String date) {
    return 'Created $date';
  }

  @override
  String creatingProjectConsumesZnn(String amount, String symbol) {
    return 'Creating a project consumes $amount $symbol that goes to the Accelerator';
  }

  @override
  String currentAmounts(Object kQsrCoinSymbol, Object kZnnCoinSymbol) {
    return 'This card displays the current $kZnnCoinSymbol and $kQsrCoinSymbol amounts for the selected address';
  }

  @override
  String currentClientChainIdentifier(int chainId) {
    return 'Current client chain identifier is $chainId';
  }

  @override
  String get currentPassword => 'Current password';

  @override
  String currentPillarSlotFee(Object coins, Object kQsrCoinSymbol) {
    return 'Current Pillar Slot fee\n$coins $kQsrCoinSymbol';
  }

  @override
  String currentSentinelSlotFee(Object coins, Object kQsrCoinSymbol) {
    return 'Current Sentinel Slot fee\n$coins $kQsrCoinSymbol';
  }

  @override
  String get dark => 'Dark';

  @override
  String get date => 'Date';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String decimals(Object number) {
    return '$number decimals';
  }

  @override
  String get delegateKey => 'DELEGATE';

  @override
  String get delegation => 'Delegation';

  @override
  String delegationPercentageGiven(Object percentage) {
    return 'Delegation percentage given: $percentage';
  }

  @override
  String get delegationReward => 'Delegation reward';

  @override
  String get delegationStats => 'Delegation Stats';

  @override
  String delegationStatsDescription(Object kZnnCoinSymbol) {
    return 'This card displays the amount of $kZnnCoinSymbol and the name of the Pillar that you delegated to';
  }

  @override
  String delegators(Object number) {
    return 'Delegators: $number';
  }

  @override
  String get deleteAllNotificationsCannotBeUndone =>
      'Are you sure you want to delete all notifications? This action cannot be undone.';

  @override
  String get deleteCache => 'Delete cache';

  @override
  String get deleteNode => 'Delete node';

  @override
  String deleteNodeConfirmation(String node) {
    return 'Are you sure you want to delete $node from the list of nodes? This action can\'t be undone.';
  }

  @override
  String get deleteNotification => 'Delete notification';

  @override
  String get deleteSwap => 'Delete swap';

  @override
  String get deleteSwapCannotBeUndone =>
      'Are you sure you want to delete this swap? This action cannot be undone.';

  @override
  String get deleteWalletCacheAndCloseApp =>
      'This option will delete the wallet cache and close the application';

  @override
  String get deposit => 'Deposit';

  @override
  String get depositAddressNotInWalletAddresses =>
      'The deposit address is not in your wallet addresses. If you created this deposit from another address in this wallet, generate additional addresses in Settings and try again.';

  @override
  String get depositAlreadyUsedInSwap =>
      'This deposit is already used in another swap.';

  @override
  String get depositDoesNotBelongToYou => 'The deposit does not belong to you.';

  @override
  String depositDurationTooLong(int maxHours) {
    return 'The deposit\'s duration is too long. Expected $maxHours hours at most.';
  }

  @override
  String get depositExpired => 'This deposit has expired.';

  @override
  String get depositExpiresIn => 'Deposit expires in';

  @override
  String get depositExpiresTooSoonForSafeSwap =>
      'This deposit will expire too soon for a safe swap.';

  @override
  String get depositHashlockAlreadyUsedInSwap =>
      'The deposit\'s hashlock is already used in another swap.';

  @override
  String get depositId => 'Deposit ID';

  @override
  String get depositIdProvidedByCounterparty =>
      'Deposit ID provided by the counterparty';

  @override
  String depositLockedUntil(String expirationDate) {
    return 'The deposit is locked until $expirationDate.';
  }

  @override
  String get depositNotIntendedForYou =>
      'This deposit is not intended for you.';

  @override
  String deposited(Object kQsrCoinSymbol) {
    return '$kQsrCoinSymbol deposited';
  }

  @override
  String get depositedAmount => 'Deposited amount';

  @override
  String get depositedAmountReclaimed => 'Deposited amount (reclaimed)';

  @override
  String depositedCoinWillBurn(Object kQsrCoinSymbol) {
    return 'All the deposited $kQsrCoinSymbol will be burned in order to create the Pillar Slot';
  }

  @override
  String get description => 'Description';

  @override
  String desktopNotificationsPreferenceStatus(String status) {
    return 'Desktop notifications preference was $status';
  }

  @override
  String desktopNotificationsStatus(String status) {
    return 'Desktop notifications $status';
  }

  @override
  String get detailedInfoAboutWalletComponents =>
      'Detailed information about wallet components';

  @override
  String get detailedInfoAboutYourProject =>
      'Detailed information about your project';

  @override
  String get deviceNotConnectedTryAgain =>
      'Not connected, please connect the device and try again.';

  @override
  String get disabled => 'disabled';

  @override
  String get disassemble => 'DISASSEMBLE';

  @override
  String disassemblePillarToUnlockCoin(Object kZnnCoinSymbol) {
    return 'You will be able to unlock the $kZnnCoinSymbol if you choose to disassemble the Pillar';
  }

  @override
  String disassembleSentinelToUnlockCoin(Object kZnnCoinSymbol) {
    return 'You will be able to unlock the $kZnnCoinSymbol if you choose to disassemble the Sentinel';
  }

  @override
  String get disconnectedFromNode => 'Disconnected from node';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get display => 'Display';

  @override
  String get displaysAccountChainInformation =>
      'This card displays information regarding the account-chain for the specified address';

  @override
  String get displaysConnectedNetworkPeers =>
      'This card displays information about connected network peers';

  @override
  String get displaysWalletNotificationsDetails =>
      'This card displays detailed information regarding the wallet notifications';

  @override
  String get displaysZenonCommunityResources =>
      'This card displays information about Zenon community resources';

  @override
  String get documentation => 'Documentation';

  @override
  String get donate => 'Donate';

  @override
  String get donationAddress => 'Donation address';

  @override
  String get donationAmountMustBePositive =>
      'Donation amount must be greater than zero';

  @override
  String get donationDetails => 'Donation details';

  @override
  String get donationSubmitted => 'Donation submitted';

  @override
  String get dragAndDropWordsCorrectOrder =>
      'Drag & drop the words in the correct order';

  @override
  String get dragAndDropWordsOnEmptyOrIncorrect =>
      'You can drag & drop words on empty boxes or incorrect words';

  @override
  String get dualCoinStats => 'Dual Coin Stats';

  @override
  String dualCoinStatsDescription(
    Object kQsrCoinSymbol,
    Object kZnnCoinSymbol,
  ) {
    return 'This card displays the circulating $kZnnCoinSymbol and $kQsrCoinSymbol supply from the network';
  }

  @override
  String get dumpMnemonic => 'Dump Mnemonic';

  @override
  String get duration => 'Duration';

  @override
  String get eachProjectComprisedOfPhases =>
      'Each project can be comprised of one or more phases. Each phase needs to be voted. Phases can be updated by the owner of the project to reflect current progress of the project.';

  @override
  String get editNode => 'Edit node';

  @override
  String get embeddedNodeSyncExplanation =>
      'By default Syrius connects to its own built-in full node, which is called the Embedded Node. It may take up to 24 hours to fully sync the network via the embedded node. During this time, you cannot send or receive transactions.\n\nIf you want to get started right away, please connect to a community node.';

  @override
  String get embeddedNodeValidatesTransactions =>
      'The Embedded Node validates all network transactions\nIt may take several hours to fully sync with the network';

  @override
  String get empty => 'Empty';

  @override
  String get emptyAccountChain => 'Empty account-chain';

  @override
  String get emptyBalance => 'Empty balance';

  @override
  String get emptyBalanceOnSelectedAddress =>
      'Empty balance on the selected address';

  @override
  String get enableClipboardWatcher => 'Enable clipboard watcher';

  @override
  String get enableDesktopNotifications => 'Enable desktop notifications';

  @override
  String get enabled => 'enabled';

  @override
  String get encryptedConnection => 'Encrypted connection';

  @override
  String get english => 'English';

  @override
  String get enterAddress => 'Enter an address';

  @override
  String get enterMessage => 'Enter message';

  @override
  String get enterPasswordToAccessWallet =>
      'Enter the password to access the wallet';

  @override
  String get enterPublicKey => 'Enter public key';

  @override
  String get enterSignature => 'Enter signature';

  @override
  String get enterSignedHash => 'Enter signed hash';

  @override
  String get enterStrongSeedVaultKey =>
      'Please enter a strong Seed Vault Key to encrypt your Seed';

  @override
  String get enterText => 'Enter text';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get enterValidDomainWithoutProtocol =>
      'Enter a valid domain without protocol (e.g. example.com)';

  @override
  String get enterWalletPasswordToDumpMnemonic =>
      'Enter the wallet password to dump the mnemonic';

  @override
  String get enterWholeNumberAmount => 'Enter a whole number amount';

  @override
  String eraseAfterFailedPasswordAttempts(int attempts) {
    return 'Erase after $attempts failed password attempts';
  }

  @override
  String get eraseWalletFilesMakeSureBackup =>
      'This option will erase the wallet files. Make sure you have a backup first';

  @override
  String get error => 'Error';

  @override
  String get errorAccessingWalletForBackup =>
      'Error while accessing wallet for backup';

  @override
  String get errorAddingNewNode => 'Error while adding new node';

  @override
  String errorAddingTokenToFavorites(Object name) {
    return 'Error adding $name token to favorites';
  }

  @override
  String get errorBurningZts => 'Error while trying to burn ZTS';

  @override
  String get errorChangingAddressLabel =>
      'Something went wrong while changing the address label';

  @override
  String get errorChangingClipboardWatcher =>
      'Something went wrong while changing clipboard watcher preference';

  @override
  String get errorChangingPassword =>
      'An error occurred while trying to change password';

  @override
  String get errorClearingNotifications => 'Error while clearing notifications';

  @override
  String get errorCollectingPillarRewards =>
      'Error while collecting Pillar rewards';

  @override
  String get errorCollectingSentinelRewards =>
      'Error while collecting Sentinel rewards';

  @override
  String get errorCollectingStakingRewards =>
      'Error while collecting staking rewards';

  @override
  String get errorCompletingSwap => 'Error while completing swap';

  @override
  String get errorConfirmingAutoEraseLimit =>
      'Error while confirming auto-erase limit';

  @override
  String get errorConfirmingAutoLockInterval =>
      'Error while confirming auto-lock interval';

  @override
  String get errorCreatingPhase => 'Error while creating phase';

  @override
  String get errorCreatingToken => 'Error while creating a new ZTS token';

  @override
  String get errorDecryptingWallet =>
      'An error occurred while trying to decrypt wallet';

  @override
  String errorDeletingNodeFromDatabase(String node) {
    return 'Error during deleting node $node from the database';
  }

  @override
  String get errorDeletingNotification => 'Error while deleting notification';

  @override
  String get errorDeletingSwap => 'Error while deleting swap';

  @override
  String get errorDeployingPillar => 'Error while deploying a Pillar';

  @override
  String get errorDeployingSentinel =>
      'Error while deploying the Sentinel Node';

  @override
  String get errorDisassemblingPillar => 'Error while disassembling Pillar';

  @override
  String get errorDisassemblingSentinel => 'Error while disassembling Sentinel';

  @override
  String get errorExportingSeedVault => 'Error while exporting Seed Vault';

  @override
  String get errorGeneratingPlasma => 'Error while generating Plasma';

  @override
  String get errorGettingVoteBreakdown =>
      'Error while trying to get the vote breakdown';

  @override
  String get errorJoiningSwap => 'Error while joining swap';

  @override
  String errorMintingToken(Object symbol) {
    return 'Error while trying to mint $symbol';
  }

  @override
  String get errorReclaimingDeposit => 'Error while reclaiming deposit';

  @override
  String errorRemovingTokenFromFavorites(Object name) {
    return 'Error removing $name token from favorites';
  }

  @override
  String get errorSettingAutoReceivePreference =>
      'Something went wrong while setting automatic receive preference';

  @override
  String get errorSettingClientChainIdentifier =>
      'Error while setting the new client chain identifier';

  @override
  String get errorSettingDesktopNotifications =>
      'Something went wrong while setting desktop notifications preference';

  @override
  String get errorSettingLaunchAtStartup =>
      'Something went wrong while setting launch at startup preference';

  @override
  String get errorSigningMessage => 'Error while signing message';

  @override
  String get errorStartingSwap => 'Error while starting swap';

  @override
  String get errorSubmittingDonation => 'Error while submitting donation';

  @override
  String get errorSubmittingProject => 'Error while submitting project';

  @override
  String get errorTransferringTokenOwnership =>
      'Error while trying to transfer token ownership';

  @override
  String get errorUndelegating => 'Error while undelegating';

  @override
  String get errorUpdatingPhase => 'Error while updating phase';

  @override
  String get errorUpdatingPillar => 'Error while updating Pillar';

  @override
  String get errorVerifyingFileHash => 'Error while verifying file hash';

  @override
  String get errorVerifyingMessage => 'Error while verifying message';

  @override
  String get errorVotingProject => 'Error while voting project';

  @override
  String get errorWhileCancellingPlasma => 'Error while cancelling Plasma';

  @override
  String get errorWhileCancellingStake => 'Error while cancelling stake';

  @override
  String get errorWhileDeactivatingPairing =>
      'Error while deactivating pairing';

  @override
  String errorWhileDepositing(Object kQsrCoinSymbol) {
    return 'Error while depositing $kQsrCoinSymbol';
  }

  @override
  String get errorWhileDisconnectingSession =>
      'Error while disconnecting session';

  @override
  String get errorWhileGeneratingNewAddress =>
      'Error while generating new address';

  @override
  String get errorWhileGeneratingStake => 'Error while generating stake';

  @override
  String errorWhileWithdrawing(Object kQsrCoinSymbol) {
    return 'Error while withdrawing $kQsrCoinSymbol';
  }

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get exchangeRate => 'Exchange Rate';

  @override
  String get expectedProducedMomentums => 'Expected/produced momentums';

  @override
  String get expiration => 'Expiration';

  @override
  String get expired => 'Expired';

  @override
  String get expiresIn => 'Expires in';

  @override
  String get explorers => 'Explorers';

  @override
  String get export => 'Export';

  @override
  String get exportSeed => 'Export Seed';

  @override
  String get exportSeedVault => 'Export Seed Vault';

  @override
  String failedToClearLocalWalletData(String error) {
    return 'Failed to clear local wallet data:\n$error\n\nWould you like to retry?';
  }

  @override
  String get failedToCompleteSwap => 'Failed to complete swap';

  @override
  String failedToCompleteSwapWithError(String error) {
    return 'Failed to complete the swap: $error';
  }

  @override
  String failedToReceiveTransaction(String error) {
    return 'Failed to receive the transaction: $error';
  }

  @override
  String fieldMustNotBeEmpty(String fieldName) {
    return '$fieldName must not be empty';
  }

  @override
  String get file => 'File';

  @override
  String get fileHashVerifiedSuccessfully => 'File hash verified successfully';

  @override
  String fileHashVerifiedWithSignedHash(String signedHash) {
    return 'File hash was successfully verified with the signed hash: $signedHash';
  }

  @override
  String get from => 'From';

  @override
  String get fuelForTheMothership => 'Fuel for the Mothership';

  @override
  String get fuse => 'Fuse';

  @override
  String fusePlasmaDescription(Object kQsrCoinSymbol) {
    return 'This card displays information about Plasma available per wallet address. A minimum of 10 $kQsrCoinSymbol are needed to be fused in order to generate Plasma. The more $kQsrCoinSymbol fused, the more Plasma is produced for the beneficiary address\n\nInsufficient Plasma: Proof-of-work for Plasma generation; limited to 1 transaction per momentum\nLow Plasma: between 10 and 89 $kQsrCoinSymbol\nAverage Plasma: between 90 and 119 $kQsrCoinSymbol\nHigh Plasma: over 120 $kQsrCoinSymbol; recommended for complex transactions (register Pillars, Sentinels, staking and issuing ZTS tokens)';
  }

  @override
  String get fusePlasmaTitle => 'Fuse Plasma';

  @override
  String fusedPlasmaDescription(Object kQsrCoinSymbol) {
    return 'This card displays all your addresses that have Plasma generated by fusing $kQsrCoinSymbol';
  }

  @override
  String get fusedPlasmaTitle => 'Fused Plasma';

  @override
  String get general => 'General';

  @override
  String get generatingPlasma => 'Generating Plasma';

  @override
  String get genericWalletAndNetworkInfo =>
      'Generic wallet & network information';

  @override
  String get goBack => 'Go back';

  @override
  String get hardwareWallet => 'Hardware wallet';

  @override
  String get hash => 'Hash';

  @override
  String get hashOrPublicKeyInvalid => 'Hash or public key invalid';

  @override
  String hashValue(Object value) {
    return 'Hash: $value';
  }

  @override
  String get hashlock => 'Hashlock';

  @override
  String get hashlockNotUnique => 'The hashlock is not unique.';

  @override
  String get hideDetails => 'Hide details';

  @override
  String hoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String hoursCount(int count) {
    return '$count h';
  }

  @override
  String get huge => 'Huge';

  @override
  String idWithValue(String id) {
    return 'ID $id';
  }

  @override
  String get importWallet => 'Import wallet';

  @override
  String get importYourWallet => 'Import your wallet';

  @override
  String get importingSeed => 'Importing seed';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get initializingWalletPleaseWait => 'Initializing wallet, please wait';

  @override
  String get innovateInspireBuild => 'Innovate. Inspire. Build.';

  @override
  String get inputAmountToSend => 'Input an amount to send';

  @override
  String get inputDepositId => 'Input the deposit ID';

  @override
  String get inputNotValidNumber => 'Input is not a valid number';

  @override
  String get inputSeedOrImportSeedVault =>
      'Input your seed or import the Seed Vault';

  @override
  String get inputSeedVaultKeyToContinue =>
      'Input the Seed Vault Key to continue';

  @override
  String get inputtedNumberHasTooManyDecimals =>
      'Inputted number has too many decimals';

  @override
  String get integratedFullNodeEnhancedSecurity =>
      'Integrated Full Node: enhanced security and privacy';

  @override
  String get invalidAddress => 'Invalid address';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get invalidHash => 'Invalid hash';

  @override
  String get invalidNode => 'Invalid Node';

  @override
  String get invalidPassword => 'Invalid password';

  @override
  String get invalidQrCode => 'Invalid QR code';

  @override
  String get invalidQrCodeException => 'Invalid QR code exception';

  @override
  String get invalidSecret => 'Invalid secret';

  @override
  String get invalidSwap => 'Invalid swap';

  @override
  String get invalidSwapSecret => 'Invalid swap secret.';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get ip => 'IP';

  @override
  String get issueToken => 'Issue Token';

  @override
  String get joinSwap => 'Join swap';

  @override
  String get joinTheAliensBuildingNom =>
      'Join the Aliens building the future on Network of Momentum';

  @override
  String get labelAlreadyExists => 'Label already exists';

  @override
  String labelAlreadyExistsInDatabase(String label) {
    return 'Label $label already exists in the database';
  }

  @override
  String get labelCannotBeEmpty => 'Label can\'t be empty';

  @override
  String labelExceedsMaxLength(String label, int length, int maxLength) {
    return 'The label $label is $length characters long, which is more than the $maxLength limit.';
  }

  @override
  String labelHasTooManyCharacters(int maxLength) {
    return 'The label has more than $maxLength characters';
  }

  @override
  String get large => 'Large';

  @override
  String get lastAttemptWalletWillReset =>
      'Last attempt. The wallet will be reset if this attempt fails';

  @override
  String get latestTransactionsDescription =>
      'This card displays the latest transactions (including ZTS tokens) of your selected address';

  @override
  String get latestTransactionsTitle => 'Latest Transactions';

  @override
  String get latestTransactionsTransferDescription =>
      'This card displays the latest transactions (including ZTS tokens) involving your wallet addresses';

  @override
  String get launchAtStartup => 'Launch at startup';

  @override
  String launchAtStartupPreferenceStatus(String status) {
    return 'Launch at startup preference was $status';
  }

  @override
  String launchAtStartupStatus(String status) {
    return 'Launch startup $status';
  }

  @override
  String ledgerWithDetails(String details) {
    return 'Ledger: $details';
  }

  @override
  String ledgerWithName(String name) {
    return 'Ledger $name';
  }

  @override
  String get level => 'Level';

  @override
  String get light => 'Light';

  @override
  String get linkToProjectArticle => 'Link to project article';

  @override
  String get listContainsAllProjects =>
      'This card displays a list that contains all the projects';

  @override
  String get listensClipboardForWalletConnectUri =>
      'Listens to the values passed to the clipboard and sends a notification when a WalletConnect URI has been copied';

  @override
  String get localTimeDiscrepancyDetected =>
      'Local time discrepancy detected. Please confirm your operating system\'s time is correct before conducting P2P swaps.';

  @override
  String get locale => 'Locale';

  @override
  String get lock => 'Lock';

  @override
  String lockAfterMinutesOfInactivity(int minutes) {
    return 'Lock after $minutes minutes of inactivity';
  }

  @override
  String locked(Object kQsrCoinSymbol) {
    return '$kQsrCoinSymbol locked';
  }

  @override
  String get makeAnotherDonation => 'Make another donation';

  @override
  String get manageReceivingFunds => 'Manage receiving funds';

  @override
  String get manageSendingFunds => 'Manage sending funds';

  @override
  String management(Object kQsrCoinSymbol) {
    return '$kQsrCoinSymbol management';
  }

  @override
  String get max => 'Max';

  @override
  String get maxSupply => 'Max supply';

  @override
  String get maxSupplyZeroForNonMintableTokens =>
      'Max supply must be 0 for non-mintable tokens';

  @override
  String get messageOrSignatureInvalid => 'Message or signature invalid';

  @override
  String get messageVerifiedSuccessfully => 'Message verified successfully';

  @override
  String messageVerifiedWithSignature(String message, String signature) {
    return 'The message: $message was successfully verified with the signature: $signature';
  }

  @override
  String get mint => 'Mint';

  @override
  String get mintable => 'Mintable';

  @override
  String get mintableToken => 'Mintable token';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String minutesCount(int count) {
    return '$count min';
  }

  @override
  String minutesLeftToJoinSwap(int minutes) {
    return 'You have <highlight>$minutes minutes</highlight> left to join the swap.';
  }

  @override
  String get mnemonicIsNotValid => 'Mnemonic is not valid';

  @override
  String get momentumHash => 'Momentum hash';

  @override
  String get momentumHeight => 'Momentum height';

  @override
  String momentumPercentageGiven(Object percentage) {
    return 'Momentum percentage given: $percentage';
  }

  @override
  String get momentumReward => 'Momentum reward';

  @override
  String get morePlasmaRequired =>
      'More Plasma is required to perform complex transactions. Please fuse enough QSR before proceeding.';

  @override
  String moreVotesNeededForQuorum(int count) {
    return '$count more votes needed to achieve quorum';
  }

  @override
  String get moreYesThanNoVotes => 'More yes than no votes';

  @override
  String get mustBeAddressFromWallet => 'Must be an address from your wallet';

  @override
  String get myProjects => 'My projects';

  @override
  String get name => 'Name';

  @override
  String get necessaryBudgetToCompletePhase =>
      'Necessary budget to successfully complete this phase';

  @override
  String get needsVoting => 'Needs voting';

  @override
  String get newOwnerAddress => 'New owner address';

  @override
  String get newPassword => 'New password';

  @override
  String get next => 'Next';

  @override
  String get no => 'no';

  @override
  String get noAccountBlocksAvailable => 'No account blocks available';

  @override
  String get noActiveProjects => 'No active projects';

  @override
  String get noActiveStakingEntries => 'No active staking entries';

  @override
  String get noDelegationStatsAvailable => 'No delegation stats available';

  @override
  String get noItemsFound => 'No items founds';

  @override
  String get noMatchingPhases => 'No matching phases found';

  @override
  String get noMoreItems => 'No more items';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noP2pSwaps => 'No P2P swaps';

  @override
  String get noPeersFound => 'No peers found';

  @override
  String get noProjectsFound => 'No projects found';

  @override
  String get noRewardsCollect => 'No rewards to collect';

  @override
  String get noRewardsInLastWeek => 'No rewards in the last week';

  @override
  String noVotesCount(int count) {
    return '$count No votes';
  }

  @override
  String get noWalletAddressSelected => 'No wallet address is selected.';

  @override
  String get noZtsTokensAvailable => 'No ZTS tokens available';

  @override
  String get nodeAddressCannotBeEmpty => 'Node address can\'t be empty';

  @override
  String get nodeAddressWithPort => 'Node address with port';

  @override
  String get nodeAlreadyExists => 'Node already exists';

  @override
  String nodeAlreadyExistsNamed(String node) {
    return 'Node $node already exists';
  }

  @override
  String nodeHasDifferentChainIdentifier(
    String node,
    int nodeChainId,
    int currentChainId,
  ) {
    return 'The node $node you are connecting to has a different chain identifier $nodeChainId than the current client chain identifier $currentChainId';
  }

  @override
  String nodeHasTooManyCharacters(int maxLength) {
    return 'The node has more than $maxLength characters';
  }

  @override
  String get nodeInformationUnavailable => 'Node information is unavailable';

  @override
  String get nodeManagement => 'Node Management';

  @override
  String get nodeNotSynced => 'Node is not synced';

  @override
  String get nodeSelection => 'Node selection';

  @override
  String get nonAlphanetChainIdentifier => 'Non-alphanet chain identifier';

  @override
  String get normal => 'Normal';

  @override
  String get notAValidKeystoreFile => 'Not a valid keystore file';

  @override
  String get notConnectedToNetwork => 'Not connected to the network';

  @override
  String get notEnoughMomentums => 'Not enough momentums';

  @override
  String get notEnoughYesVotes => 'Not enough yes votes';

  @override
  String get notifications => 'Notifications';

  @override
  String numberOfDecimals(Object number) {
    return 'Number of decimals: $number';
  }

  @override
  String get numberRequired => 'Number required';

  @override
  String get ok => 'OK';

  @override
  String get oldestSwapDeletedWhenFull =>
      'The oldest swap entry will be deleted when a new swap is started.';

  @override
  String get onScreenQrScanner => 'On-screen QR Scanner';

  @override
  String get onlyAccepted => 'Only accepted';

  @override
  String get onlyMacOsSupported => 'Only macOS is supported at the moment';

  @override
  String get options => 'Options';

  @override
  String get otherWalletOptions => 'Other wallet options';

  @override
  String get ownZtsToken => 'You own this ZTS token';

  @override
  String ownerWithAddress(String address) {
    return 'Owner $address';
  }

  @override
  String get p2pSwapAddressHint => 'Enter NoM address';

  @override
  String get p2pSwapCounterpartyAddressDescription =>
      'The address of the trading partner for the swap.';

  @override
  String get p2pSwapFillDetails => 'Fill in the swap details';

  @override
  String get p2pSwapGeneratingPlasma => 'Please wait while Plasma is generated';

  @override
  String p2pSwapHours(Object hours) {
    return '$hours hours';
  }

  @override
  String get p2pSwapJoinDescription =>
      'Join a native swap started by a counterparty.';

  @override
  String get p2pSwapMachineOnly =>
      'The swap must be completed on this machine.';

  @override
  String get p2pSwapOptionsDescription =>
      'Starting and joining P2P swaps can be done from this card.';

  @override
  String get p2pSwapOptionsTitle => 'P2P Swap Options';

  @override
  String get p2pSwapOwnAddressError => 'Cannot swap with your own address';

  @override
  String p2pSwapReclaimFunds(String duration) {
    return 'You can reclaim your funds in <highlight>$duration</highlight> if the counterparty fails to join the swap.';
  }

  @override
  String get p2pSwapStart => 'Start swap';

  @override
  String get p2pSwapStartDescription =>
      'Start a native swap with a counterparty.';

  @override
  String get p2pSwapWaitForCounterparty =>
      'After starting the swap, wait for the counterparty to join the swap with the agreed upon amount.';

  @override
  String get p2pSwapWarningDescription =>
      'Please note that the P2P swap is an experimental feature and may result in funds being lost.\n\nUse the feature with caution and consider splitting large swaps into multiple smaller ones.';

  @override
  String get p2pSwapWarningTitle => 'Before continuing';

  @override
  String get p2pSwaps => 'P2P Swaps';

  @override
  String get p2pSwapsConductedWithWallet =>
      'This card displays a list of P2P swaps that have been conducted with this wallet.';

  @override
  String get paid => 'Paid';

  @override
  String get pairingFailed => 'Pairing failed';

  @override
  String get pairingTopic => 'Pairing Topic';

  @override
  String get password => 'Password';

  @override
  String get passwordNotStrongEnough => 'Password not strong enough';

  @override
  String get passwordRequiredToUnlockWallet =>
      'This is the password that will be required to unlock the wallet';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get pasteFromClipboard => 'Paste from clipboard';

  @override
  String get pasteWalletConnectLinkHere => 'Paste the WalletConnect link here';

  @override
  String get peers => 'Peers';

  @override
  String get peersAvailable => 'Peers available';

  @override
  String get peersConnected => 'Peers connected';

  @override
  String get pending => 'Pending';

  @override
  String get pendingTransactionsDescription =>
      'This card displays the pending transactions (including ZTS tokens) for the selected address';

  @override
  String get pendingTransactionsTitle => 'Pending Transactions';

  @override
  String get percentageDelegationRewardsGiven =>
      'Percentage of delegation rewards given to the delegators';

  @override
  String get percentageOfMomentumRewards =>
      'Percentage of momentum rewards given to the delegators';

  @override
  String get permissionRequired => 'Permission required';

  @override
  String phaseBelongsToProject(String projectId) {
    return 'This phase belongs to Project ID $projectId';
  }

  @override
  String get phaseDescription => 'Phase description';

  @override
  String get phaseDetails => 'Phase details';

  @override
  String get phaseList => 'Phase List';

  @override
  String get phaseName => 'Phase name';

  @override
  String get phaseNeedsVoting => 'Phase needs voting';

  @override
  String get phaseUrl => 'Phase URL';

  @override
  String get pillar => 'Pillar';

  @override
  String get pillarCollectDescription =>
      'This card displays your current Pillar rewards (either from your Pillar Node or from your delegation) that are ready to be collected. If there are any rewards available, you will be able to collect them. In order to receive rewards, the Pillar Node needs to be not only registered in the network, but also deployed (use znn-controller for this operation) and it must produce momentums';

  @override
  String get pillarCollectTitle => 'Pillar Collect';

  @override
  String get pillarDelegationError => 'Pillar delegation error';

  @override
  String get pillarDetails => 'Pillar details';

  @override
  String get pillarMomentumAddress => 'Pillar momentum address';

  @override
  String get pillarMomentumRewards => 'Pillar momentum rewards';

  @override
  String get pillarName => 'Pillar name';

  @override
  String get pillarNameAlreadyExists => 'Pillar name already exists';

  @override
  String get pillarProducerAddress => 'Pillar producer address';

  @override
  String get pillarProducerAddressDifferentSeed =>
      'Pillar producer address must be generated from a different seed';

  @override
  String get pillarRegistered => 'Pillar registered';

  @override
  String get pillarRewardAddress => 'Pillar reward address';

  @override
  String get pillarRewardsBlockCreated =>
      'Successfully created block for collecting the pillar rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.';

  @override
  String get pillarRewardsDescription =>
      'This card displays a chart with your Pillar rewards. Pillar rewards are generated either by operating a Pillar Node or from delegations to a Pillar Node';

  @override
  String get pillarRewardsTitle => 'Pillar Rewards';

  @override
  String get pillarStats => 'Pillar Stats';

  @override
  String get pillarUpdate => 'Pillar update';

  @override
  String get pillarUpdated => 'Pillar updated';

  @override
  String get pillars => 'Pillars';

  @override
  String pillarsCanStillVote(int count) {
    return '$count Pillars that can still cast a vote';
  }

  @override
  String get pillarsDescription =>
      'This card displays the number of active Pillars in the network';

  @override
  String pillarsListDescription(Object kZnnCoinSymbol) {
    return 'This card displays Pillar Nodes that are currently active in the network. The list contains the name of the Pillar, the associated producer address, the weight (total number of delegations) and your delegation status. You can choose to delegate your $kZnnCoinSymbol balance to any Pillar in order to receive delegation rewards in $kZnnCoinSymbol. You can undelegate the balance at any time, without any penalties. Minimum delegation amount is 1 $kZnnCoinSymbol per address';
  }

  @override
  String get pillarsListTitle => 'Pillars List';

  @override
  String get pillarsTitle => 'Pillars';

  @override
  String pillarsWithNumber(Object number) {
    return 'Pillars: $number';
  }

  @override
  String get plasma => 'Plasma';

  @override
  String get plasmaCheck => 'Plasma Check';

  @override
  String get plasmaGenerationIdle => 'Plasma generation idle';

  @override
  String plasmaStatsDescription(Object kQsrCoinSymbol) {
    return 'This card displays information about current Plasma level for each wallet address. Plasma is used as an anti-spam mechanism. More Plasma you have per address, more transactions you will be able to send or receive on that address. Low or insufficient Plasma will require proof-of-work for generation. Fuse 10 $kQsrCoinSymbol or more in order to obtain Plasma for any given address\n\nInsufficient Plasma: Proof-of-work for Plasma generation; limited to 1 transaction per momentum\nLow Plasma: between 10 and 50 $kQsrCoinSymbol\nAverage Plasma: between 50 and 119 $kQsrCoinSymbol\nHigh Plasma: over 120 $kQsrCoinSymbol; recommended to make complex transactions (deploy Pillars, Sentinels, staking and issuing ZTS tokens)';
  }

  @override
  String get plasmaStatsTitle => 'Plasma Stats';

  @override
  String get pleaseScanValidWalletConnectQr =>
      'Please scan a valid WalletConnect QR code';

  @override
  String get preferences => 'Preferences';

  @override
  String get pressToReceive => 'Press to receive the transaction';

  @override
  String get proceedAnyway => 'Proceed anyway';

  @override
  String get producerAddress => 'Producer Address';

  @override
  String get projectCreation => 'Project creation';

  @override
  String get projectDescription => 'Project description';

  @override
  String get projectDetails => 'Project details';

  @override
  String get projectHasNoPhases => 'The project has no phases';

  @override
  String get projectList => 'Project List';

  @override
  String get projectName => 'Project name';

  @override
  String get projectStats => 'Project Stats';

  @override
  String get projectSubmitted => 'Project submitted';

  @override
  String get projectUrl => 'Project URL';

  @override
  String get publicKey => 'Public Key';

  @override
  String get qrCodeScanFailed => 'QR code scan failed';

  @override
  String get qsrAmount => 'QSR Amount';

  @override
  String quasarTransactions(Object quasar) {
    return '$quasar transactions';
  }

  @override
  String get quorumAchieved => 'Quorum achieved';

  @override
  String get quorumNotAchieved => 'Quorum not achieved';

  @override
  String get realtimeStats => 'Realtime Stats';

  @override
  String realtimeStatsDescription(
    Object kQsrCoinSymbol,
    Object kZnnCoinSymbol,
  ) {
    return 'This card displays the number of $kZnnCoinSymbol and $kQsrCoinSymbol transactions. For example, a delegation is considered a $kZnnCoinSymbol transaction from the network\'s perspective. Every interaction with the network embedded contracts is internally considered a transaction';
  }

  @override
  String get receive => 'Receive';

  @override
  String get receiveSwappedFundsToAddress =>
      'You will receive the swapped funds to this address.';

  @override
  String get receiveTransactionFailed => 'Receive transaction failed';

  @override
  String get received => 'Received';

  @override
  String get receiver => 'Receiver';

  @override
  String get receivingWrongTokenOrAmount =>
      'I\'m receiving the wrong token or amount.';

  @override
  String get recipient => 'Recipient';

  @override
  String get recipientAddress => 'Recipient Address';

  @override
  String get reclaimDeposit => 'Reclaim deposit';

  @override
  String get reclaimExpiredDepositWithId =>
      'If you have lost access to the machine that a swap was started on, the expired deposit can be reclaimed with the deposit ID.\n\nIf you don\'t have the deposit ID, please refer to the swap tutorial for instructions on how to find it using a block explorer.';

  @override
  String get reclaimFunds => 'Reclaim funds';

  @override
  String get reclaimFundsIfCounterpartyFails =>
      'You can reclaim your funds if the counterparty fails to complete the swap.';

  @override
  String get reclaimTransactionSentFundsShortly =>
      'Reclaim transaction sent. You will receive the funds shortly.';

  @override
  String get reclaimableFunds => 'Reclaimable funds';

  @override
  String get reclaimingFundsPleaseWait =>
      'Reclaiming. This will take a moment.';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get register => 'Register';

  @override
  String get registerAnotherPillar => 'Register another Pillar';

  @override
  String get registerPillar => 'Register Pillar';

  @override
  String get registerSentinel => 'Register Sentinel';

  @override
  String get registeredUse => ' registered. Use ';

  @override
  String get rejected => 'Rejected';

  @override
  String get remaining => 'Remaining';

  @override
  String remainingBudgetForNextPhases(
    String znnAmount,
    String znnSymbol,
    String qsrAmount,
    String qsrSymbol,
  ) {
    return 'Remaining budget for the next phases is $znnAmount $znnSymbol and $qsrAmount $qsrSymbol';
  }

  @override
  String get repeatNewPassword => 'Repeat new password';

  @override
  String requiredForPillarSlot(Object coins, Object kQsrCoinSymbol) {
    return '$coins $kQsrCoinSymbol required for a Pillar slot';
  }

  @override
  String requiredForSentinelNode(Object coins, Object kQsrCoinSymbol) {
    return '$coins $kQsrCoinSymbol required for a Sentinel Node';
  }

  @override
  String get reset => 'Reset';

  @override
  String get resetWallet => 'Reset wallet';

  @override
  String get resolvingAddressConfirmOnDevice =>
      'Resolving address, please confirm the address on your hardware device';

  @override
  String get returnToProjectList => 'Return to project list';

  @override
  String get revocationWindowOpen => 'Revocation window is open';

  @override
  String get saveQr => 'Save QR';

  @override
  String get scanDevices => 'Scan devices';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get scanWalletConnectQrFromDapp =>
      'Scan the WalletConnect QR from the dApp';

  @override
  String get scanWalletConnectQrUsingCamera =>
      'Scan a WalletConnect QR code using the built-in camera of this device';

  @override
  String get scanWalletConnectQrUsingOnScreenScanner =>
      'Scan the WalletConnect QR code using an on-screen QR scanner. This requires the screen recording permission';

  @override
  String get screenRecordingPermissionRequired =>
      'Screen Recording permission is required to scan and process the on-screen WalletConnect QR code';

  @override
  String get searchByIdNameDescriptionUrl =>
      'Search by id, name, description, or URL';

  @override
  String get searchByIdOwnerNameDescriptionUrl =>
      'Search by id, owner, name, description, or URL';

  @override
  String get searchTokenHint =>
      'Search by name, symbol, owner, or token standard';

  @override
  String get searching => 'Searching';

  @override
  String secondsAgo(int count) {
    return '$count s ago';
  }

  @override
  String secondsCount(int count) {
    return '$count s';
  }

  @override
  String get security => 'Security';

  @override
  String get seeMore => 'See more';

  @override
  String get seed => 'Seed';

  @override
  String get seedVault => 'Seed Vault';

  @override
  String get seedVaultBackupExplanation =>
      'A Seed Vault is an encrypted file for backing up your Seed. The Seed is encrypted with a Seed Vault Key and cannot be accessed without it. Make sure you backup your Seed Vault in multiple offline locations (e.g. USB, external HDD) and do not lose your Seed Vault Key. If you lose the Seed Vault file or you don\'t remember the Seed Vault Key you lose access to your funds.';

  @override
  String get seedVaultExported => 'Seed Vault successfully exported';

  @override
  String seedVaultExportedToPath(String path) {
    return 'The Seed Vault was successfully exported to $path';
  }

  @override
  String get seedVaultKey => 'Seed Vault Key';

  @override
  String get selectDefaultAddressForOperations =>
      'Select the default address that will be used throughout the wallet for any network operation';

  @override
  String get selectOptionToAccessWallet =>
      'Select an option to access your wallet';

  @override
  String get selectToConnectDevice => 'Select to connect the device';

  @override
  String get send => 'Send';

  @override
  String get sendTransaction => 'send transaction';

  @override
  String get sender => 'Sender';

  @override
  String get senderAddressDescription =>
      'The address from which the transaction will be sent';

  @override
  String get sendingTransaction => 'Sending transaction';

  @override
  String get sent => 'Sent';

  @override
  String sentDetails(
    Object amount,
    Object recipient,
    Object sender,
    Object symbol,
  ) {
    return 'Sent $amount $symbol from $sender to $recipient';
  }

  @override
  String get sentinel => 'Sentinel';

  @override
  String get sentinelAddress => 'Sentinel Address';

  @override
  String get sentinelCollectDescription =>
      'This card displays your current Sentinel rewards that are ready to be collected. If there are any rewards available, you will be able to collect them. In order to receive rewards, the Sentinel Node needs to be not only registered in the network, but also deployed (use znn-controller for this operation) and it must have >90% daily uptime';

  @override
  String get sentinelCollectTitle => 'Sentinel Collect';

  @override
  String get sentinelDetectedOnThisAddress =>
      'Sentinel detected on this address';

  @override
  String get sentinelRegistered => 'Sentinel registered';

  @override
  String get sentinelRewardsBlockCreated =>
      'Successfully created block for collecting the sentinel rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.';

  @override
  String get sentinelRewardsDescription =>
      'This card displays a chart with your Sentinel rewards from your Sentinel Node';

  @override
  String get sentinelRewardsTitle => 'Sentinel Rewards';

  @override
  String get sentinelStats => 'Sentinel Stats';

  @override
  String get sentinels => 'Sentinels';

  @override
  String get sentinelsDescription =>
      'This card displays the number of active Sentinels in the network';

  @override
  String get sentinelsListDescription =>
      'This card displays information about the Sentinels that are currently active in the network';

  @override
  String get sentinelsListTitle => 'Sentinels List';

  @override
  String get sessionTopic => 'Session Topic';

  @override
  String get setBudgetForProject => 'Set a budget for the project';

  @override
  String get setZnnNodeToConnect =>
      'This card allows one to set the ZNN Node used to connect to. By default the wallet is connected to the Embedded Node. If you are running a local ZNN Node, please use the localhost option';

  @override
  String get shareDepositIdWithCounterparty =>
      'Send your deposit ID to the counterparty via a messaging service so that they can join the swap.';

  @override
  String get shareQr => 'Share QR';

  @override
  String get showDetails => 'Show details';

  @override
  String get showcaseProgressOfProject =>
      'Showcase the progress of your project (e.g. Git PR/commit)';

  @override
  String get sign => 'Sign';

  @override
  String get signFile => 'Sign file';

  @override
  String get signature => 'Signature';

  @override
  String get signedHash => 'Signed hash';

  @override
  String get small => 'Small';

  @override
  String get socialMedia => 'Social Media';

  @override
  String get someNodeInformationUnavailable =>
      'Some node information is unavailable';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get sortByLastUpdate => 'Sort by last update';

  @override
  String get spawn => 'Spawn';

  @override
  String get stake => 'Stake';

  @override
  String get stakeCollectDescription =>
      'This card displays your current staking rewards that are ready to be collected. If there are any rewards available, you will be able to collect them';

  @override
  String get stakeCollectTitle => 'Stake Collect';

  @override
  String get stakesListDescription =>
      'This card displays information about the stake entries for the selected address';

  @override
  String get stakesListTitle => 'Stakes';

  @override
  String get stakingDuration => 'Staking duration';

  @override
  String get stakingRewardsBlockCreated =>
      'Successfully created block for collecting the staking rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.';

  @override
  String get stakingRewardsDescription =>
      'This card displays a chart with your staking rewards from your staking entries';

  @override
  String get stakingRewardsTitle => 'Staking Rewards';

  @override
  String get stakingStats => 'Staking Stats';

  @override
  String stakingStatsDescription(Object kZnnCoinSymbol) {
    return 'This card displays the number of staking entries and the total $kZnnCoinSymbol that you are currently staking';
  }

  @override
  String get startProjectByCreatingPhase =>
      'Start the project by creating a phase to unlock funds';

  @override
  String get started => 'Started';

  @override
  String get starting => 'Starting';

  @override
  String get startingSwapPleaseWait =>
      'Starting swap. This will take a moment.';

  @override
  String get status => 'Status';

  @override
  String get storeSeedVaultOfflineLocations =>
      'Store your Seed Vault and Seed Vault Key in secure and separate offline locations. You will need both to access your funds';

  @override
  String get submit => 'Submit';

  @override
  String get submitDonation => 'Submit donation';

  @override
  String get submitPhase => 'Submit phase';

  @override
  String get submitProject => 'Submit project';

  @override
  String get successfully => 'successfully';

  @override
  String successfullyAddedNode(String node) {
    return 'Successfully added node $node';
  }

  @override
  String successfullyBurned(Object amount, Object symbol) {
    return 'Successfully burned $amount $symbol';
  }

  @override
  String successfullyBurnedRequestedAmount(
    Object amount,
    Object hash,
    Object symbol,
  ) {
    return 'You have successfully burned the requested amount: $amount $symbol $hash';
  }

  @override
  String successfullyConnectedToNode(String node) {
    return 'Successfully connected to $node';
  }

  @override
  String successfullyMinted(Object amount, Object symbol) {
    return 'Successfully minted $amount $symbol';
  }

  @override
  String successfullyMintedRequestedAmount(
    Object amount,
    Object hash,
    Object symbol,
  ) {
    return 'You have successfully minted the requested amount: $amount $symbol $hash';
  }

  @override
  String get sufficientPlasma => 'Sufficient Plasma';

  @override
  String get swap => 'Swap';

  @override
  String get swapAddressNotInDefaultAddresses =>
      'Swap address not in default addresses. Please add the address in the addresses list.';

  @override
  String get swapCompleted => 'Swap completed.';

  @override
  String get swapCompletedFundsSoon =>
      'Swap completed. You will receive the funds shortly.';

  @override
  String get swapDoesNotExist => 'Swap does not exist';

  @override
  String swapExpiresIn(String duration) {
    return 'The swap will expire in $duration';
  }

  @override
  String get swapExpiresTooSoonForSafeSwap =>
      'The swap will expire too soon for a safe swap.';

  @override
  String get swapHistoryFull => 'Swap history is full';

  @override
  String get swapJoined => 'Swap joined.';

  @override
  String get swapReclaimBlockCreated =>
      'Successfully created block for reclaiming swap funds.';

  @override
  String get swapSecret => 'Swap secret';

  @override
  String get swapSecretExceedsMaxSize =>
      'The swap secret size exceeds the maximum allowed size.';

  @override
  String get swapStarted => 'Swap started.';

  @override
  String get swapUnsuccessful => 'The swap was unsuccessful.';

  @override
  String get swapUnsuccessfulWaitForExpiration =>
      'The swap was unsuccessful.\nPlease wait for your deposit to expire to reclaim your funds.';

  @override
  String get swapping => 'Swapping';

  @override
  String get syriusCachePath => 'Syrius cache path';

  @override
  String get syriusGitBranchName => 'Syrius git branch name';

  @override
  String get syriusGitCommitDate => 'Syrius git commit date';

  @override
  String get syriusGitCommitHash => 'Syrius git commit hash';

  @override
  String get syriusGitCommitMessage => 'Syrius git commit message';

  @override
  String get syriusGitOriginUrl => 'Syrius git origin url';

  @override
  String get syriusWalletPath => 'Syrius wallet path';

  @override
  String get syriusWalletType => 'Syrius wallet type';

  @override
  String get syriusWalletVersion => 'Syrius wallet version';

  @override
  String get system => 'System';

  @override
  String get textScaleChangeFailed => 'Text scale change failed';

  @override
  String get textScaleChanged => 'Text scale changed';

  @override
  String textScaleChangedDetails(String scale) {
    return 'Text scale successfully changed to $scale';
  }

  @override
  String get textScaling => 'Text scaling';

  @override
  String get thankYouForSupportingAccelerator =>
      'Thank you for supporting the Accelerator';

  @override
  String get theme => 'Theme';

  @override
  String get themeModeChangeFailed => 'Theme mode change failed';

  @override
  String get themeModeChanged => 'Theme mode changed';

  @override
  String themeModeChangedDetails(String mode) {
    return 'Theme mode successfully changed to $mode';
  }

  @override
  String thisIsYourWordsSeed(int wordCount) {
    return 'This is your $wordCount words seed';
  }

  @override
  String get time => 'Time';

  @override
  String get timestamp => 'Timestamp';

  @override
  String get to => 'To';

  @override
  String tokenAddedToFavorites(Object name) {
    return '$name token has been added to favorites';
  }

  @override
  String get tokenBalanceDescription =>
      'This card displays information about ZTS tokens that you currently hold in your wallet';

  @override
  String get tokenBalanceTitle => 'Token Balance';

  @override
  String get tokenBurnTooltip =>
      'When enabled, any holder can burn tokens from their own balance. When disabled, only the token owner can burn.';

  @override
  String get tokenCreation => 'ZNN Check';

  @override
  String get tokenDetails => 'Details';

  @override
  String get tokenDomain => 'Token Domain';

  @override
  String get tokenDomainCannotBeEmpty => 'Token domain cannot be empty';

  @override
  String tokenDomainMaxLength(int maxLength) {
    return 'Token domain must be at most $maxLength characters';
  }

  @override
  String get tokenInFavorites => 'This token is in your favorites.';

  @override
  String get tokenIssuanceAddressDescription =>
      'This will be your issuance address';

  @override
  String get tokenMetrics => 'Metrics';

  @override
  String get tokenMintableBurnableOptions => 'Mintable and Burnable Options';

  @override
  String tokenMintableBurnableSubtitle(Object burnable, Object mintable) {
    return 'Mintable: $mintable\nBurnable: $burnable';
  }

  @override
  String get tokenMintableTooltip =>
      'Whether or not this token is mintable after creation';

  @override
  String get tokenName => 'Token Name';

  @override
  String get tokenNameAllowedCharacters =>
      'Token name must use letters and numbers, with optional single \'-\', \'.\', or \'_\' separators between them';

  @override
  String get tokenNameCannotBeEmpty => 'Token name cannot be empty';

  @override
  String tokenNameMaxLength(int maxLength) {
    return 'Token name must be at most $maxLength characters';
  }

  @override
  String get tokenNotInFavorites => 'This token is not in your favorites.';

  @override
  String tokenRemovedFromFavorites(Object name) {
    return '$name token has been removed from favorites';
  }

  @override
  String get tokenStandard => 'Token standard';

  @override
  String get tokenStatusUtilityTooltip =>
      'Token status: utility or non-utility (e.g. security token)';

  @override
  String tokenSummary(Object name, Object symbol, Object tokenStandard) {
    return 'Token $name with symbol $symbol and ZTS $tokenStandard';
  }

  @override
  String tokenSupplyOutOfMax(
    Object maxSupply,
    Object symbol,
    Object totalSupply,
  ) {
    return '$totalSupply out of $maxSupply $symbol';
  }

  @override
  String get tokenSymbol => 'Token Symbol';

  @override
  String tokenSymbolCannotBe(String symbols) {
    return 'Token symbol cannot be $symbols';
  }

  @override
  String get tokenSymbolCannotBeEmpty => 'Token symbol cannot be empty';

  @override
  String tokenSymbolMaxLength(int maxLength) {
    return 'Token symbol must be at most $maxLength characters';
  }

  @override
  String get tokenSymbolUppercaseAlphanumericOnly =>
      'Token symbol must contain only uppercase letters and numbers';

  @override
  String get tokenTransactions => 'Token Transactions';

  @override
  String get tokenVerified => 'This token is verified.';

  @override
  String get tokens => 'Tokens';

  @override
  String get tokensCardDescription =>
      'This card displays a grid with all the ZTS tokens from the network, including ZTS tokens issued by you';

  @override
  String get topic => 'Topic';

  @override
  String get total => 'Total';

  @override
  String get totalDonationBudget => 'Total donation budget';

  @override
  String get totalPhaseBudget => 'Total phase budget';

  @override
  String get totalProjectBudget => 'Total project budget';

  @override
  String get totalSupply => 'Total supply';

  @override
  String totalVotesCount(int count) {
    return '$count votes in total';
  }

  @override
  String get transactionError => 'Error while receiving transaction';

  @override
  String transactionHashWithValue(String hash) {
    return 'Transaction hash: $hash';
  }

  @override
  String transactionReceivedOnAddress(String address) {
    return 'Transaction received on $address';
  }

  @override
  String get transactions => 'Transactions';

  @override
  String get transactionsDescription =>
      'This card displays the total number of transactions settled in the last hour across the network';

  @override
  String get transactionsLastHour => 'transactions in the last hour';

  @override
  String get transfer => 'Transfer';

  @override
  String get transferDescription =>
      'Redirects you to the Transfer tab where you can manage sending and receiving funds';

  @override
  String get transferTokenOwnership => 'Transfer token ownership';

  @override
  String transferredTokenOwnership(Object name) {
    return 'Successfully transferred ownership of $name token';
  }

  @override
  String transferredTokenOwnershipToAddress(Object address, Object name) {
    return 'Successfully transferred ownership of $name token to address $address';
  }

  @override
  String get type => 'Type';

  @override
  String get unableToAddDepositAddressToWallet =>
      'Unable to add the deposit address to your wallet addresses. Generate additional addresses in Settings and try again.';

  @override
  String get unableToRetrieveTokenInformation =>
      'Unable to retrieve token information.';

  @override
  String get unableToVerifyDepositCreationTime =>
      'Unable to verify the deposit creation time.';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get uncheckToDisableAutoReceiver =>
      'Uncheck to disable the auto-receiver and receive transactions manually';

  @override
  String get undelegate => 'UNDELEGATE';

  @override
  String get unencryptedConnection => 'Unencrypted connection';

  @override
  String get unlockFailed => 'Unlock failed';

  @override
  String get unlockYourSeedVault => 'Unlock your Seed Vault';

  @override
  String get unsuccessful => 'Unsuccessful';

  @override
  String get unsupportedWalletFileType => 'Unsupported wallet file type';

  @override
  String get untilRevocationWindowOpens => 'Until revocation window opens';

  @override
  String get update => 'Update';

  @override
  String get updatePhase => 'Update phase';

  @override
  String get updatePillar => 'Update Pillar';

  @override
  String get updatePillarSettings => 'Update Pillar settings';

  @override
  String get updatingPhaseResetsVotes =>
      'Updating this phase will reset all current votes';

  @override
  String get uptime => 'Uptime';

  @override
  String get uriInvalid => 'URI invalid';

  @override
  String get url => 'URL';

  @override
  String get usDateFormat => 'MM/dd/yyyy';

  @override
  String get useStrongPasswordRequirements =>
      'Use a password that has at least 8 characters, one number, one uppercase letter, one lowercase letter and one symbol';

  @override
  String get userCanceledQrScanning =>
      'User canceled the QR scanning operation';

  @override
  String get userQrScanCanceled => 'User QR scan canceled';

  @override
  String get utilityToken => 'Utility token';

  @override
  String get valueCannotBeEmpty => 'Value can\'t be empty';

  @override
  String get valueIsNull => 'Value is null';

  @override
  String valueMustBe(String value) {
    return 'Value must be $value';
  }

  @override
  String valueMustBeBetween(String minValue, String maxValue) {
    return 'Value must be between $minValue and $maxValue';
  }

  @override
  String get valueMustBeZero => 'Value must be 0';

  @override
  String get verify => 'Verify';

  @override
  String get verifyFile => 'Verify file';

  @override
  String verifyNonFavoriteToken(String tokenStandard) {
    return 'You are receiving a token that is not in your favorites. Please verify that the token standard is correct: $tokenStandard';
  }

  @override
  String get viewMyTokens => 'View my Tokens';

  @override
  String get viewPhases => 'View phases';

  @override
  String get viewPillars => 'View Pillars';

  @override
  String get viewProjects => 'View projects';

  @override
  String get viewSentinels => 'View Sentinels';

  @override
  String get viewSwapTutorial => 'View swap tutorial';

  @override
  String visitDomain(Object domain) {
    return 'Visit $domain';
  }

  @override
  String get votingClosed => 'Voting closed';

  @override
  String votingClosesIn(String duration) {
    return 'Voting closes in $duration';
  }

  @override
  String get votingOpen => 'Voting open';

  @override
  String get votingResults => 'Voting results';

  @override
  String waitToReclaimIncorrectDeposit(String expirationDate) {
    return 'If the token or the amount you are receiving is not what you have agreed upon, wait until your deposit expires to reclaim your funds.\nYour deposit will expire at $expirationDate.';
  }

  @override
  String get waitingForCounterpartyKeepRunning =>
      'Waiting for the counterparty. Please keep Syrius running.';

  @override
  String get waitingForCounterpartyToJoin =>
      'Waiting for the counterparty to join the swap.';

  @override
  String get waitingForDataFetching => 'Waiting for data fetching';

  @override
  String get walletAppearanceAndThemeSettings =>
      'Wallet appearance and theme settings';

  @override
  String get walletConnectLink => 'WalletConnect Link';

  @override
  String get walletConnectPairingDescription =>
      'A pairing refers to the initial process of establishing a secure connection between a wallet and the dApp. Once the pairing is complete, a session is established, which allows the dApp to communicate with the wallet securely over the Internet';

  @override
  String get walletConnectPairingList => 'WalletConnect Pairing List';

  @override
  String get walletConnectSessionDescription =>
      'A session refers to a live connection between a user\'s wallet and a dApp. A session allows the dApp to communicate with the wallet securely over the Internet';

  @override
  String get walletConnectSessionsList => 'WalletConnect Sessions List';

  @override
  String get walletConnectUri => 'WalletConnect URI';

  @override
  String get walletFileDoesNotExist => 'Wallet file does not exist';

  @override
  String get walletFileTooLarge =>
      'Wallet file is too large to be a valid keystore file';

  @override
  String get walletNotAutoLocked =>
      'Your wallet will not be auto-locked while the swap is in progress.';

  @override
  String get walletNotUnlocked => 'Wallet is not unlocked.';

  @override
  String get walletOptions => 'Wallet Options';

  @override
  String get walletPathNotRegularFile =>
      'Selected wallet path is not a regular file';

  @override
  String get walletResetFailed => 'Wallet reset failed';

  @override
  String get walletSuccessfullyCreated =>
      'The wallet has been successfully created';

  @override
  String get websites => 'Websites';

  @override
  String get weight => 'Weight';

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get willSecurelyStoreSeedVault =>
      'I will securely store the Seed Vault & Seed Vault Key';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get writeDownAndExportSeedSafely =>
      'Please carefully write down your seed and export it to a safe location';

  @override
  String get writtenDownMySeed => 'I have written down my seed';

  @override
  String get yes => 'yes';

  @override
  String yesVotesCount(int count) {
    return '$count Yes votes';
  }

  @override
  String get youAreAllSet => 'You\'re all set';

  @override
  String get youAreReceiving => 'You are receiving';

  @override
  String get youAreSending => 'You are sending';

  @override
  String youHaveDeposited(Object coins, Object kQsrCoinSymbol) {
    return 'You have deposited $coins $kQsrCoinSymbol';
  }

  @override
  String get yourAddress => 'Your address';

  @override
  String get yourDepositId => 'Your deposit ID';

  @override
  String get yourDonationMatters => 'Your donation matters';

  @override
  String get yourProjectOwnerAddress =>
      'This will be your project owner address';

  @override
  String get zenonBitcoinTalk => 'Zenon Bitcoin Talk';

  @override
  String get zenonDiscord => 'Zenon Discord';

  @override
  String get zenonExplorer => 'Zenon Explorer';

  @override
  String get zenonGithub => 'Zenon Github';

  @override
  String get zenonHub => 'Zenon Hub';

  @override
  String get zenonHubExplorer => 'Zenon Hub Explorer';

  @override
  String get zenonMainDataPath => 'Zenon main data path';

  @override
  String get zenonMedium => 'Zenon Medium';

  @override
  String get zenonNetwork => 'Zenon Network';

  @override
  String get zenonNodeBuildVersion => 'Zenon Node build version';

  @override
  String get zenonNodeChainIdentifier => 'Zenon Node chain identifier';

  @override
  String get zenonNodeGitCommitHash => 'Zenon Node git commit hash';

  @override
  String get zenonNodeKernelVersion => 'Zenon Node kernel version';

  @override
  String get zenonNodeNumberOfProcessors => 'Zenon Node number of processors';

  @override
  String get zenonNodeOperatingSystem => 'Zenon Node operating system';

  @override
  String get zenonNodePlatform => 'Zenon Node platform';

  @override
  String get zenonNodePlatformVersion => 'Zenon Node platform version';

  @override
  String get zenonOrgCommunity => 'Zenon ORG Community';

  @override
  String get zenonOrgCommunityForum => 'Zenon ORG Community Forum';

  @override
  String get zenonOrgCommunityWiki => 'ZenonORG Community Wiki';

  @override
  String get zenonReddit => 'Zenon Reddit';

  @override
  String get zenonSdkVersion => 'Zenon SDK version';

  @override
  String get zenonTelegram => 'Zenon Telegram';

  @override
  String get zenonTools => 'Zenon Tools';

  @override
  String zenonTransactions(Object zenon) {
    return '$zenon transactions';
  }

  @override
  String get zenonTwitter => 'Zenon Twitter';

  @override
  String get zenonWhitepaper => 'Zenon Whitepaper';

  @override
  String get zenonWiki => 'Zenon Wiki';

  @override
  String get zenonYoutube => 'Zenon Youtube';

  @override
  String get znnAmount => 'ZNN Amount';

  @override
  String get znnController => 'znn-controller ';

  @override
  String get znnDonationSubmittedQsrFailed =>
      'ZNN donation was submitted, but the QSR donation failed. Retry to submit only the remaining QSR donation.';

  @override
  String get ztsSearchDescription =>
      'Coins and tokens can be searched by name - \"Zenon\" -, by symbol - \"ZNN\" -, and by token standard - \"zts1znnxxxxxxxxxxxxx9z4ulx\"';
}
