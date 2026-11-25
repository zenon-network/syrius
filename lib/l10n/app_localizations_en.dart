// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get active => 'Active';

  @override
  String get activePillars => 'Active Pillars';

  @override
  String get activeSentinels => 'Active Sentinels';

  @override
  String get activeSwap => 'Active swap';

  @override
  String get address => 'Address';

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
  String get allDonatedFundsGoToAccelerator =>
      'All donated funds go directly into the Accelerator address';

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
  String get available => 'Available';

  @override
  String get balance => 'Balance';

  @override
  String get balanceUnavailableForAddress =>
      'Balance is unavailable for the selected address';

  @override
  String get beneficiaryAddress => 'Beneficiary address';

  @override
  String get cancel => 'Cancel';

  @override
  String get cannotJoinSwapExpiresTooSoon =>
      'Cannot join swap. The swap will expire too soon for a safe swap.';

  @override
  String get cancelPlasmaConfirmation =>
      'Are you sure you want to cancel the Plasma fusion?';

  @override
  String get checkPillarStatus => ' to check the Pillar status';

  @override
  String get checkSentinelStatus => ' to check the Sentinel status';

  @override
  String get clickToAddToFavorites => 'Click to add to favorites';

  @override
  String get clickToRemoveFromFavorites => 'Click to remove from favorites';

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
  String get completed => 'Completed';

  @override
  String get cannotReuseAddressForSentinel =>
      'If this address previously revoked a Sentinel, it cannot create a new Sentinel again. Use a different address before depositing QSR.';

  @override
  String couldNotSend(Object amount, Object recipient, Object symbol) {
    return 'Couldn\'t send $amount $symbol to $recipient';
  }

  @override
  String get burn => 'Burn';

  @override
  String get burnableToken => 'Burnable by any holder';

  @override
  String burnTokenIssueFee(Object amount, Object symbol) {
    return 'You will need to burn $amount $symbol to issue a token';
  }

  @override
  String consumeZnnToSubmitProject(String amount, String symbol) {
    return 'Consume $amount $symbol to submit the project';
  }

  @override
  String get continueText => 'Continue';

  @override
  String get copyDepositId => 'Copy deposit ID';

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
  String currentPillarSlotFee(Object coins, Object kQsrCoinSymbol) {
    return 'Current Pillar Slot fee\n$coins $kQsrCoinSymbol';
  }

  @override
  String currentSentinelSlotFee(Object coins, Object kQsrCoinSymbol) {
    return 'Current Sentinel Slot fee\n$coins $kQsrCoinSymbol';
  }

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
  String get deposit => 'Deposit';

  @override
  String get depositExpiresIn => 'Deposit expires in';

  @override
  String get depositId => 'Deposit ID';

  @override
  String get depositIdProvidedByCounterparty =>
      'Deposit ID provided by the counterparty';

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
  String get deleteSwap => 'Delete swap';

  @override
  String get deleteSwapCannotBeUndone =>
      'Are you sure you want to delete this swap? This action cannot be undone.';

  @override
  String get detailedInfoAboutYourProject =>
      'Detailed information about your project';

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
  String get dualCoinStats => 'Dual Coin Stats';

  @override
  String dualCoinStatsDescription(
    Object kQsrCoinSymbol,
    Object kZnnCoinSymbol,
  ) {
    return 'This card displays the circulating $kZnnCoinSymbol and $kQsrCoinSymbol supply from the network';
  }

  @override
  String get duration => 'Duration';

  @override
  String get eachProjectComprisedOfPhases =>
      'Each project can be comprised of one or more phases. Each phase needs to be voted. Phases can be updated by the owner of the project to reflect current progress of the project.';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get exchangeRate => 'Exchange Rate';

  @override
  String get error => 'Error';

  @override
  String get errorCreatingPhase => 'Error while creating phase';

  @override
  String get errorCreatingToken => 'Error while creating a new ZTS token';

  @override
  String errorAddingTokenToFavorites(Object name) {
    return 'Error adding $name token to favorites';
  }

  @override
  String get errorBurningZts => 'Error while trying to burn ZTS';

  @override
  String get errorCompletingSwap => 'Error while completing swap';

  @override
  String get errorDeletingSwap => 'Error while deleting swap';

  @override
  String get errorCollectingPillarRewards =>
      'Error while collecting Pillar rewards';

  @override
  String get errorCollectingSentinelRewards =>
      'Error while collecting Sentinel rewards';

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
  String get errorCollectingStakingRewards =>
      'Error while collecting staking rewards';

  @override
  String get errorGettingVoteBreakdown =>
      'Error while trying to get the vote breakdown';

  @override
  String get errorSubmittingDonation => 'Error while submitting donation';

  @override
  String get errorSubmittingProject => 'Error while submitting project';

  @override
  String get errorUndelegating => 'Error while undelegating';

  @override
  String get errorUpdatingPhase => 'Error while updating phase';

  @override
  String get errorUpdatingPillar => 'Error while updating Pillar';

  @override
  String get errorVotingProject => 'Error while voting project';

  @override
  String get errorWhileCancellingPlasma => 'Error while cancelling Plasma';

  @override
  String get errorWhileCancellingStake => 'Error while cancelling stake';

  @override
  String get errorGeneratingPlasma => 'Error while generating Plasma';

  @override
  String errorMintingToken(Object symbol) {
    return 'Error while trying to mint $symbol';
  }

  @override
  String get errorJoiningSwap => 'Error while joining swap';

  @override
  String get errorReclaimingDeposit => 'Error while reclaiming deposit';

  @override
  String errorRemovingTokenFromFavorites(Object name) {
    return 'Error removing $name token from favorites';
  }

  @override
  String get errorTransferringTokenOwnership =>
      'Error while trying to transfer token ownership';

  @override
  String errorWhileDepositing(Object kQsrCoinSymbol) {
    return 'Error while depositing $kQsrCoinSymbol';
  }

  @override
  String get errorWhileGeneratingStake => 'Error while generating stake';

  @override
  String get errorStartingSwap => 'Error while starting swap';

  @override
  String errorWhileWithdrawing(Object kQsrCoinSymbol) {
    return 'Error while withdrawing $kQsrCoinSymbol';
  }

  @override
  String get expiration => 'Expiration';

  @override
  String get expired => 'Expired';

  @override
  String get expiresIn => 'Expires in';

  @override
  String get expectedProducedMomentums => 'Expected/produced momentums';

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
  String get goBack => 'Go back';

  @override
  String get hAgo => 'h ago';

  @override
  String get hash => 'Hash';

  @override
  String get hashlock => 'Hashlock';

  @override
  String hashValue(Object value) {
    return 'Hash: $value';
  }

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
  String idWithValue(String id) {
    return 'ID $id';
  }

  @override
  String get innovateInspireBuild => 'Innovate. Inspire. Build.';

  @override
  String get inputAmountToSend => 'Input an amount to send';

  @override
  String get inputDepositId => 'Input the deposit ID';

  @override
  String get inputtedNumberHasTooManyDecimals =>
      'Inputted number has too many decimals';

  @override
  String get issueToken => 'Issue Token';

  @override
  String get joinSwap => 'Join swap';

  @override
  String get joinTheAliensBuildingNom =>
      'Join the Aliens building the future on Network of Momentum';

  @override
  String get latestTransactionsDescription =>
      'This card displays the latest transactions (including ZTS tokens) of your selected address';

  @override
  String get latestTransactionsTitle => 'Latest Transactions';

  @override
  String get latestTransactionsTransferDescription =>
      'This card displays the latest transactions (including ZTS tokens) involving your wallet addresses';

  @override
  String get level => 'Level';

  @override
  String get linkToProjectArticle => 'Link to project article';

  @override
  String get listContainsAllProjects =>
      'This card displays a list that contains all the projects';

  @override
  String locked(Object kQsrCoinSymbol) {
    return '$kQsrCoinSymbol locked';
  }

  @override
  String get localTimeDiscrepancyDetected =>
      'Local time discrepancy detected. Please confirm your operating system\'s time is correct before conducting P2P swaps.';

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
  String get minAgo => 'min ago';

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
  String get mint => 'Mint';

  @override
  String get mintable => 'Mintable';

  @override
  String get mintableToken => 'Mintable token';

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
  String get next => 'Next';

  @override
  String get no => 'no';

  @override
  String get noActiveProjects => 'No active projects';

  @override
  String get noItemsFound => 'No items founds';

  @override
  String get noMatchingPhases => 'No matching phases found';

  @override
  String get noMoreItems => 'No more items';

  @override
  String get noP2pSwaps => 'No P2P swaps';

  @override
  String get noProjectsFound => 'No projects found';

  @override
  String get noRewardsCollect => 'No rewards to collect';

  @override
  String noVotesCount(int count) {
    return '$count No votes';
  }

  @override
  String get noZtsTokensAvailable => 'No ZTS tokens available';

  @override
  String get notEnoughYesVotes => 'Not enough yes votes';

  @override
  String numberOfDecimals(Object number) {
    return 'Number of decimals: $number';
  }

  @override
  String get oldestSwapDeletedWhenFull =>
      'The oldest swap entry will be deleted when a new swap is started.';

  @override
  String get onlyAccepted => 'Only accepted';

  @override
  String get options => 'Options';

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
  String get password => 'Password';

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
  String get pillarProducerAddress => 'Pillar producer address';

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
  String plasmaStatsDescription(Object kQsrCoinSymbol) {
    return 'This card displays information about current Plasma level for each wallet address. Plasma is used as an anti-spam mechanism. More Plasma you have per address, more transactions you will be able to send or receive on that address. Low or insufficient Plasma will require proof-of-work for generation. Fuse 10 $kQsrCoinSymbol or more in order to obtain Plasma for any given address\n\nInsufficient Plasma: Proof-of-work for Plasma generation; limited to 1 transaction per momentum\nLow Plasma: between 10 and 50 $kQsrCoinSymbol\nAverage Plasma: between 50 and 119 $kQsrCoinSymbol\nHigh Plasma: over 120 $kQsrCoinSymbol; recommended to make complex transactions (deploy Pillars, Sentinels, staking and issuing ZTS tokens)';
  }

  @override
  String get plasmaStatsTitle => 'Plasma Stats';

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
  String pillarsWithNumber(Object number) {
    return 'Pillars: $number';
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
  String get plasma => 'Plasma';

  @override
  String get plasmaCheck => 'Plasma Check';

  @override
  String get pressToReceive => 'Press to receive the transaction';

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
  String get reclaimFunds => 'Reclaim funds';

  @override
  String get reclaimableFunds => 'Reclaimable funds';

  @override
  String get reclaimFundsIfCounterpartyFails =>
      'You can reclaim your funds if the counterparty fails to complete the swap.';

  @override
  String get reclaimingFundsPleaseWait =>
      'Reclaiming. This will take a moment.';

  @override
  String get receiveSwappedFundsToAddress =>
      'You will receive the swapped funds to this address.';

  @override
  String get reclaimDeposit => 'Reclaim deposit';

  @override
  String get reclaimExpiredDepositWithId =>
      'If you have lost access to the machine that a swap was started on, the expired deposit can be reclaimed with the deposit ID.\n\nIf you don\'t have the deposit ID, please refer to the swap tutorial for instructions on how to find it using a block explorer.';

  @override
  String get reclaimTransactionSentFundsShortly =>
      'Reclaim transaction sent. You will receive the funds shortly.';

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
  String requiredForPillarSlot(Object coins, Object kQsrCoinSymbol) {
    return '$coins $kQsrCoinSymbol required for a Pillar slot';
  }

  @override
  String requiredForSentinelNode(Object coins, Object kQsrCoinSymbol) {
    return '$coins $kQsrCoinSymbol required for a Sentinel Node';
  }

  @override
  String get returnToProjectList => 'Return to project list';

  @override
  String get revocationWindowOpen => 'Revocation window is open';

  @override
  String get sAgo => 's ago';

  @override
  String get saveQr => 'Save QR';

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
  String get send => 'Send';

  @override
  String get sendTransaction => 'send transaction';

  @override
  String get sentinel => 'Sentinel';

  @override
  String get sender => 'Sender';

  @override
  String get senderAddressDescription =>
      'The address from which the transaction will be sent';

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
  String get sendingTransaction => 'Sending transaction';

  @override
  String get sentinelAddress => 'Sentinel Address';

  @override
  String get sentinelCollectDescription =>
      'This card displays your current Sentinel rewards that are ready to be collected. If there are any rewards available, you will be able to collect them. In order to receive rewards, the Sentinel Node needs to be not only registered in the network, but also deployed (use znn-controller for this operation) and it must have >90% daily uptime';

  @override
  String get sentinelCollectTitle => 'Sentinel Collect';

  @override
  String get sentinelRewardsDescription =>
      'This card displays a chart with your Sentinel rewards from your Sentinel Node';

  @override
  String get sentinelRewardsBlockCreated =>
      'Successfully created block for collecting the sentinel rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.';

  @override
  String get sentinelRewardsTitle => 'Sentinel Rewards';

  @override
  String get sentinelDetectedOnThisAddress =>
      'Sentinel detected on this address';

  @override
  String get sentinelRegistered => 'Sentinel registered';

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
  String get setBudgetForProject => 'Set a budget for the project';

  @override
  String get shareQr => 'Share QR';

  @override
  String get shareDepositIdWithCounterparty =>
      'Send your deposit ID to the counterparty via a messaging service so that they can join the swap.';

  @override
  String get showDetails => 'Show details';

  @override
  String get showcaseProgressOfProject =>
      'Showcase the progress of your project (e.g. Git PR/commit)';

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
  String get stakingDuration => 'Staking duration';

  @override
  String get stakingStats => 'Staking Stats';

  @override
  String stakingStatsDescription(Object kZnnCoinSymbol) {
    return 'This card displays the number of staking entries and the total $kZnnCoinSymbol that you are currently staking';
  }

  @override
  String get stakesListDescription =>
      'This card displays information about the stake entries for the selected address';

  @override
  String get stakesListTitle => 'Stakes';

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
  String get stakingRewardsDescription =>
      'This card displays a chart with your staking rewards from your staking entries';

  @override
  String get stakingRewardsBlockCreated =>
      'Successfully created block for collecting the staking rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.';

  @override
  String get stakingRewardsTitle => 'Staking Rewards';

  @override
  String get status => 'Status';

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
  String get swapCompleted => 'Swap completed.';

  @override
  String get swapCompletedFundsSoon =>
      'Swap completed. You will receive the funds shortly.';

  @override
  String get swapJoined => 'Swap joined.';

  @override
  String swapExpiresIn(String duration) {
    return 'The swap will expire in $duration';
  }

  @override
  String get swapHistoryFull => 'Swap history is full';

  @override
  String get swapReclaimBlockCreated =>
      'Successfully created block for reclaiming swap funds.';

  @override
  String get swapSecret => 'Swap secret';

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
  String get thankYouForSupportingAccelerator =>
      'Thank you for supporting the Accelerator';

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
  String get tokenInFavorites => 'This token is in your favorites.';

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
  String get tokenTransactions => 'Token Transactions';

  @override
  String get tokenVerified => 'This token is verified.';

  @override
  String get tokens => 'Tokens';

  @override
  String get tokensCardDescription =>
      'This card displays a grid with all the ZTS tokens from the network, including ZTS tokens issued by you';

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
  String visitDomain(Object domain) {
    return 'Visit $domain';
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
  String transferredTokenOwnership(Object name) {
    return 'Successfully transferred ownership of $name token';
  }

  @override
  String transferredTokenOwnershipToAddress(Object address, Object name) {
    return 'Successfully transferred ownership of $name token to address $address';
  }

  @override
  String get transferTokenOwnership => 'Transfer token ownership';

  @override
  String get type => 'Type';

  @override
  String get undelegate => 'UNDELEGATE';

  @override
  String get unsuccessful => 'Unsuccessful';

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
  String get utilityToken => 'Utility token';

  @override
  String get usDateFormat => 'MM/dd/yyyy';

  @override
  String get valueMustBeZero => 'Value must be 0';

  @override
  String verifyNonFavoriteToken(String tokenStandard) {
    return 'You are receiving a token that is not in your favorites. Please verify that the token standard is correct: $tokenStandard';
  }

  @override
  String get viewPhases => 'View phases';

  @override
  String get viewProjects => 'View projects';

  @override
  String get viewSwapTutorial => 'View swap tutorial';

  @override
  String get viewPillars => 'View Pillars';

  @override
  String get viewMyTokens => 'View my Tokens';

  @override
  String get viewSentinels => 'View Sentinels';

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
  String get waitingForDataFetching => 'Waiting for data fetching';

  @override
  String get waitingForCounterpartyToJoin =>
      'Waiting for the counterparty to join the swap.';

  @override
  String get waitingForCounterpartyKeepRunning =>
      'Waiting for the counterparty. Please keep Syrius running.';

  @override
  String waitToReclaimIncorrectDeposit(String expirationDate) {
    return 'If the token or the amount you are receiving is not what you have agreed upon, wait until your deposit expires to reclaim your funds.\nYour deposit will expire at $expirationDate.';
  }

  @override
  String get weight => 'Weight';

  @override
  String get walletNotAutoLocked =>
      'Your wallet will not be auto-locked while the swap is in progress.';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get yes => 'yes';

  @override
  String yesVotesCount(int count) {
    return '$count Yes votes';
  }

  @override
  String youHaveDeposited(Object coins, Object kQsrCoinSymbol) {
    return 'You have deposited $coins $kQsrCoinSymbol';
  }

  @override
  String get youAreReceiving => 'You are receiving';

  @override
  String get youAreSending => 'You are sending';

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
  String zenonTransactions(Object zenon) {
    return '$zenon transactions';
  }

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
