// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get activePillars => 'Active Pillars';

  @override
  String get activeSentinels => 'Active Sentinels';

  @override
  String get address => 'Address';

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
  String get amount => 'Amount';

  @override
  String areYouSureTranfer(Object amount, Object recipient, Object symbol) {
    return 'Are you sure you want to transfer $amount $symbol to $recipient ?';
  }

  @override
  String get asset => 'Asset';

  @override
  String get balance => 'Balance';

  @override
  String get beneficiaryAddress => 'Beneficiary address';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelPlasmaConfirmation =>
      'Are you sure you want to cancel the Plasma fusion?';

  @override
  String get checkPillarStatus => ' to check the Pillar status';

  @override
  String get checkSentinelStatus => ' to check the Sentinel status';

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
  String get cannotReuseAddressForSentinel =>
      'If this address previously revoked a Sentinel, it cannot create a new Sentinel again. Use a different address before depositing QSR.';

  @override
  String couldNotSend(Object amount, Object recipient, Object symbol) {
    return 'Couldn\'t send $amount $symbol to $recipient';
  }

  @override
  String get burn => 'Burn';

  @override
  String burnTokenIssueFee(Object amount, Object symbol) {
    return 'You will need to burn $amount $symbol to issue a token';
  }

  @override
  String get continueText => 'Continue';

  @override
  String get create => 'Create';

  @override
  String get createAnotherToken => 'Create another Token';

  @override
  String get createPillarDescription =>
      'Start the process of deploying a Pillar Node in the network';

  @override
  String get createPillarTitle => 'Create Pillar';

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
  String deposited(Object kQsrCoinSymbol) {
    return '$kQsrCoinSymbol deposited';
  }

  @override
  String depositedCoinWillBurn(Object kQsrCoinSymbol) {
    return 'All the deposited $kQsrCoinSymbol will be burned in order to create the Pillar Slot';
  }

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
  String get errorCreatingToken => 'Error while creating a new ZTS token';

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
  String get errorUndelegating => 'Error while undelegating';

  @override
  String get errorUpdatingPillar => 'Error while updating Pillar';

  @override
  String get errorWhileCancellingPlasma => 'Error while cancelling Plasma';

  @override
  String get errorWhileCancellingStake => 'Error while cancelling stake';

  @override
  String get errorGeneratingPlasma => 'Error while generating Plasma';

  @override
  String errorWhileDepositing(Object kQsrCoinSymbol) {
    return 'Error while depositing $kQsrCoinSymbol';
  }

  @override
  String get errorWhileGeneratingStake => 'Error while generating stake';

  @override
  String errorWhileWithdrawing(Object kQsrCoinSymbol) {
    return 'Error while withdrawing $kQsrCoinSymbol';
  }

  @override
  String get expiration => 'Expiration';

  @override
  String get expectedProducedMomentums => 'Expected/produced momentums';

  @override
  String get from => 'from';

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
  String hashValue(Object value) {
    return 'Hash: $value';
  }

  @override
  String get issueToken => 'Issue Token';

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
  String locked(Object kQsrCoinSymbol) {
    return '$kQsrCoinSymbol locked';
  }

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
  String get mintable => 'Mintable';

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
  String get name => 'Name';

  @override
  String get next => 'Next';

  @override
  String get no => 'no';

  @override
  String get noItemsFound => 'No items founds';

  @override
  String get noMoreItems => 'No more items';

  @override
  String get noRewardsCollect => 'No rewards to collect';

  @override
  String numberOfDecimals(Object number) {
    return 'Number of decimals: $number';
  }

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
  String get pillar => 'Pillar';

  @override
  String get pillarCollectDescription =>
      'This card displays your current Pillar rewards (either from your Pillar Node or from your delegation) that are ready to be collected. If there are any rewards available, you will be able to collect them. In order to receive rewards, the Pillar Node needs to be not only registered in the network, but also deployed (use znn-controller for this operation) and it must produce momentums';

  @override
  String get pillarCollectTitle => 'Pillar Collect';

  @override
  String get pillarDelegationError => 'Pillar delegation error';

  @override
  String get pillarDeployment => 'Pillar deployment: Plasma check';

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
  String get pressToReceive => 'Press to receive the transaction';

  @override
  String get producerAddress => 'Producer Address';

  @override
  String quasarTransactions(Object quasar) {
    return '$quasar transactions';
  }

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
  String get receiver => 'Receiver';

  @override
  String get recipientAddress => 'Recipient Address';

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
  String requiredForPillarSlot(Object coins, Object kQsrCoinSymbol) {
    return '$coins $kQsrCoinSymbol required for a Pillar slot';
  }

  @override
  String requiredForSentinelNode(Object coins, Object kQsrCoinSymbol) {
    return '$coins $kQsrCoinSymbol required for a Sentinel Node';
  }

  @override
  String get revocationWindowOpen => 'Revocation window is open';

  @override
  String get sAgo => 's ago';

  @override
  String get saveQr => 'Save QR';

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
  String get sentinelDeployment => 'Sentinel deployment: Plasma check';

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
  String get shareQr => 'Share QR';

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
  String get stakingRewardsDescription =>
      'This card displays a chart with your staking rewards from your staking entries';

  @override
  String get stakingRewardsBlockCreated =>
      'Successfully created block for collecting the staking rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.';

  @override
  String get stakingRewardsTitle => 'Staking Rewards';

  @override
  String get successfully => 'successfully';

  @override
  String get sufficientPlasma => 'Sufficient Plasma';

  @override
  String get to => 'to';

  @override
  String get tokenTransactions => 'Token Transactions';

  @override
  String get tokenBurnTooltip =>
      'Whether or not only the token owner can burn it';

  @override
  String get tokenCreation => 'Token Creation';

  @override
  String get tokenCreationPlasmaCheck => 'Token creation: Plasma check';

  @override
  String get tokenDetails => 'Token Details';

  @override
  String get tokenDomain => 'Token Domain';

  @override
  String get tokenIssuanceAddressDescription =>
      'This will be your issuance address';

  @override
  String get tokenMetrics => 'Token Metrics';

  @override
  String get tokenMintableBurnableOptions =>
      'Token mintable and burnable options';

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
  String get tokenStatusUtilityTooltip =>
      'Token status: utility or non-utility (e.g. security token)';

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
  String get totalSupply => 'Total supply';

  @override
  String get transactionError => 'Error while receiving transaction';

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
  String get type => 'Type';

  @override
  String get undelegate => 'UNDELEGATE';

  @override
  String get untilRevocationWindowOpens => 'Until revocation window opens';

  @override
  String get update => 'Update';

  @override
  String get updatePillar => 'Update Pillar';

  @override
  String get updatePillarSettings => 'Update Pillar settings';

  @override
  String get uptime => 'Uptime';

  @override
  String get utilityToken => 'Utility token';

  @override
  String get usDateFormat => 'MM/dd/yyyy';

  @override
  String get viewPillars => 'View Pillars';

  @override
  String get viewMyTokens => 'View my Tokens';

  @override
  String get viewSentinels => 'View Sentinels';

  @override
  String get waitingForDataFetching => 'Waiting for data fetching';

  @override
  String get weight => 'Weight';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get yes => 'yes';

  @override
  String youHaveDeposited(Object coins, Object kQsrCoinSymbol) {
    return 'You have deposited $coins $kQsrCoinSymbol';
  }

  @override
  String zenonTransactions(Object zenon) {
    return '$zenon transactions';
  }

  @override
  String get znnController => 'znn-controller ';

  @override
  String get ztsSearchDescription =>
      'Coins and tokens can be searched by name - \"Zenon\" -, by symbol - \"ZNN\" -, and by token standard - \"zts1znnxxxxxxxxxxxxx9z4ulx\"';
}
