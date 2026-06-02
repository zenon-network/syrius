import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @activePillars.
  ///
  /// In en, this message translates to:
  /// **'Active Pillars'**
  String get activePillars;

  /// No description provided for @activeSentinels.
  ///
  /// In en, this message translates to:
  /// **'Active Sentinels'**
  String get activeSentinels;

  /// No description provided for @addressSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Addresses can be searched by label - \"Address 1\" - and by hex value - \"z1qxemdeddedxt0kenxxxxxxxxxxxxxxxxh9amk0\"'**
  String get addressSearchDescription;

  /// No description provided for @addressToCollectRewards.
  ///
  /// In en, this message translates to:
  /// **'The address that will be able to collect the Pillar rewards'**
  String get addressToCollectRewards;

  /// No description provided for @addressToProduceMomentums.
  ///
  /// In en, this message translates to:
  /// **'The address that will produce momentums, get it from znn-controller'**
  String get addressToProduceMomentums;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @areYouSureTranfer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to transfer {amount} {symbol} to {recipient} ?'**
  String areYouSureTranfer(Object amount, Object recipient, Object symbol);

  /// No description provided for @asset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get asset;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @checkPillarStatus.
  ///
  /// In en, this message translates to:
  /// **' to check the Pillar status'**
  String get checkPillarStatus;

  /// No description provided for @coin.
  ///
  /// In en, this message translates to:
  /// **'Coin'**
  String get coin;

  /// No description provided for @collect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collect;

  /// No description provided for @collectPillarRewards.
  ///
  /// In en, this message translates to:
  /// **'Collect Pillar rewards'**
  String get collectPillarRewards;

  /// No description provided for @collectSentinelRewards.
  ///
  /// In en, this message translates to:
  /// **'Collect Sentinel rewards'**
  String get collectSentinelRewards;

  /// No description provided for @couldNotSend.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send {amount} {symbol} to {recipient}'**
  String couldNotSend(Object amount, Object recipient, Object symbol);

  /// No description provided for @createPillarDescription.
  ///
  /// In en, this message translates to:
  /// **'Start the process of deploying a Pillar Node in the network'**
  String get createPillarDescription;

  /// No description provided for @createPillarTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Pillar'**
  String get createPillarTitle;

  /// No description provided for @currentAmounts.
  ///
  /// In en, this message translates to:
  /// **'This card displays the current {kZnnCoinSymbol} and {kQsrCoinSymbol} amounts for the selected address'**
  String currentAmounts(Object kQsrCoinSymbol, Object kZnnCoinSymbol);

  /// No description provided for @currentPillarSlotFee.
  ///
  /// In en, this message translates to:
  /// **'Current Pillar Slot fee\n{coins} {kQsrCoinSymbol}'**
  String currentPillarSlotFee(Object coins, Object kQsrCoinSymbol);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @delegateKey.
  ///
  /// In en, this message translates to:
  /// **'DELEGATE'**
  String get delegateKey;

  /// No description provided for @delegation.
  ///
  /// In en, this message translates to:
  /// **'Delegation'**
  String get delegation;

  /// No description provided for @delegationPercentageGiven.
  ///
  /// In en, this message translates to:
  /// **'Delegation percentage given: {percentage}'**
  String delegationPercentageGiven(Object percentage);

  /// No description provided for @delegationReward.
  ///
  /// In en, this message translates to:
  /// **'Delegation reward'**
  String get delegationReward;

  /// No description provided for @delegationStats.
  ///
  /// In en, this message translates to:
  /// **'Delegation Stats'**
  String get delegationStats;

  /// No description provided for @delegationStatsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the amount of {kZnnCoinSymbol} and the name of the Pillar that you delegated to'**
  String delegationStatsDescription(Object kZnnCoinSymbol);

  /// No description provided for @delegators.
  ///
  /// In en, this message translates to:
  /// **'Delegators: {number}'**
  String delegators(Object number);

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @deposited.
  ///
  /// In en, this message translates to:
  /// **'{kQsrCoinSymbol} deposited'**
  String deposited(Object kQsrCoinSymbol);

  /// No description provided for @depositedCoinWillBurn.
  ///
  /// In en, this message translates to:
  /// **'All the deposited {kQsrCoinSymbol} will be burned in order to create the Pillar Slot'**
  String depositedCoinWillBurn(Object kQsrCoinSymbol);

  /// No description provided for @disassemble.
  ///
  /// In en, this message translates to:
  /// **'DISASSEMBLE'**
  String get disassemble;

  /// No description provided for @disassemblePillarToUnlockCoin.
  ///
  /// In en, this message translates to:
  /// **'You will be able to unlock the {kZnnCoinSymbol} if you choose to disassemble the Pillar'**
  String disassemblePillarToUnlockCoin(Object kZnnCoinSymbol);

  /// No description provided for @dualCoinStats.
  ///
  /// In en, this message translates to:
  /// **'Dual Coin Stats'**
  String get dualCoinStats;

  /// No description provided for @dualCoinStatsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the circulating {kZnnCoinSymbol} and {kQsrCoinSymbol} supply from the network'**
  String dualCoinStatsDescription(Object kQsrCoinSymbol, Object kZnnCoinSymbol);

  /// No description provided for @errorCollectingPillarRewards.
  ///
  /// In en, this message translates to:
  /// **'Error while collecting Pillar rewards'**
  String get errorCollectingPillarRewards;

  /// No description provided for @errorCollectingSentinelRewards.
  ///
  /// In en, this message translates to:
  /// **'Error while collecting Sentinel rewards'**
  String get errorCollectingSentinelRewards;

  /// No description provided for @errorDeployingPillar.
  ///
  /// In en, this message translates to:
  /// **'Error while deploying a Pillar'**
  String get errorDeployingPillar;

  /// No description provided for @errorDisassemblingPillar.
  ///
  /// In en, this message translates to:
  /// **'Error while disassembling Pillar'**
  String get errorDisassemblingPillar;

  /// No description provided for @errorUndelegating.
  ///
  /// In en, this message translates to:
  /// **'Error while undelegating'**
  String get errorUndelegating;

  /// No description provided for @errorUpdatingPillar.
  ///
  /// In en, this message translates to:
  /// **'Error while updating Pillar'**
  String get errorUpdatingPillar;

  /// No description provided for @errorWhileDepositing.
  ///
  /// In en, this message translates to:
  /// **'Error while depositing {kQsrCoinSymbol}'**
  String errorWhileDepositing(Object kQsrCoinSymbol);

  /// No description provided for @errorWhileWithdrawing.
  ///
  /// In en, this message translates to:
  /// **'Error while withdrawing {kQsrCoinSymbol}'**
  String errorWhileWithdrawing(Object kQsrCoinSymbol);

  /// No description provided for @expectedProducedMomentums.
  ///
  /// In en, this message translates to:
  /// **'Expected/produced momentums'**
  String get expectedProducedMomentums;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get from;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @hAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get hAgo;

  /// No description provided for @hash.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get hash;

  /// No description provided for @hashValue.
  ///
  /// In en, this message translates to:
  /// **'Hash: {value}'**
  String hashValue(Object value);

  /// No description provided for @latestTransactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the latest transactions (including ZTS tokens) of your selected address'**
  String get latestTransactionsDescription;

  /// No description provided for @latestTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest Transactions'**
  String get latestTransactionsTitle;

  /// No description provided for @latestTransactionsTransferDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the latest transactions (including ZTS tokens) involving your wallet addresses'**
  String get latestTransactionsTransferDescription;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'{kQsrCoinSymbol} locked'**
  String locked(Object kQsrCoinSymbol);

  /// No description provided for @manageReceivingFunds.
  ///
  /// In en, this message translates to:
  /// **'Manage receiving funds'**
  String get manageReceivingFunds;

  /// No description provided for @manageSendingFunds.
  ///
  /// In en, this message translates to:
  /// **'Manage sending funds'**
  String get manageSendingFunds;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'{kQsrCoinSymbol} management'**
  String management(Object kQsrCoinSymbol);

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get minAgo;

  /// No description provided for @momentumPercentageGiven.
  ///
  /// In en, this message translates to:
  /// **'Momentum percentage given: {percentage}'**
  String momentumPercentageGiven(Object percentage);

  /// No description provided for @momentumReward.
  ///
  /// In en, this message translates to:
  /// **'Momentum reward'**
  String get momentumReward;

  /// No description provided for @morePlasmaRequired.
  ///
  /// In en, this message translates to:
  /// **'More Plasma is required to perform complex transactions. Please fuse enough QSR before proceeding.'**
  String get morePlasmaRequired;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items founds'**
  String get noItemsFound;

  /// No description provided for @noMoreItems.
  ///
  /// In en, this message translates to:
  /// **'No more items'**
  String get noMoreItems;

  /// No description provided for @noRewardsCollect.
  ///
  /// In en, this message translates to:
  /// **'No rewards to collect'**
  String get noRewardsCollect;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pendingTransactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the pending transactions (including ZTS tokens) for the selected address'**
  String get pendingTransactionsDescription;

  /// No description provided for @pendingTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Transactions'**
  String get pendingTransactionsTitle;

  /// No description provided for @percentageDelegationRewardsGiven.
  ///
  /// In en, this message translates to:
  /// **'Percentage of delegation rewards given to the delegators'**
  String get percentageDelegationRewardsGiven;

  /// No description provided for @percentageOfMomentumRewards.
  ///
  /// In en, this message translates to:
  /// **'Percentage of momentum rewards given to the delegators'**
  String get percentageOfMomentumRewards;

  /// No description provided for @pillar.
  ///
  /// In en, this message translates to:
  /// **'Pillar'**
  String get pillar;

  /// No description provided for @pillarCollectDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays your current Pillar rewards (either from your Pillar Node or from your delegation) that are ready to be collected. If there are any rewards available, you will be able to collect them. In order to receive rewards, the Pillar Node needs to be not only registered in the network, but also deployed (use znn-controller for this operation) and it must produce momentums'**
  String get pillarCollectDescription;

  /// No description provided for @pillarCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Pillar Collect'**
  String get pillarCollectTitle;

  /// No description provided for @pillarDelegationError.
  ///
  /// In en, this message translates to:
  /// **'Pillar delegation error'**
  String get pillarDelegationError;

  /// No description provided for @pillarDeployment.
  ///
  /// In en, this message translates to:
  /// **'Pillar deployment: Plasma check'**
  String get pillarDeployment;

  /// No description provided for @pillarDetails.
  ///
  /// In en, this message translates to:
  /// **'Pillar details'**
  String get pillarDetails;

  /// No description provided for @pillarMomentumAddress.
  ///
  /// In en, this message translates to:
  /// **'Pillar momentum address'**
  String get pillarMomentumAddress;

  /// No description provided for @pillarMomentumRewards.
  ///
  /// In en, this message translates to:
  /// **'Pillar momentum rewards'**
  String get pillarMomentumRewards;

  /// No description provided for @pillarName.
  ///
  /// In en, this message translates to:
  /// **'Pillar name'**
  String get pillarName;

  /// No description provided for @pillarProducerAddress.
  ///
  /// In en, this message translates to:
  /// **'Pillar producer address'**
  String get pillarProducerAddress;

  /// No description provided for @pillarRegistered.
  ///
  /// In en, this message translates to:
  /// **'Pillar registered'**
  String get pillarRegistered;

  /// No description provided for @pillarRewardAddress.
  ///
  /// In en, this message translates to:
  /// **'Pillar reward address'**
  String get pillarRewardAddress;

  /// No description provided for @pillarRewardsBlockCreated.
  ///
  /// In en, this message translates to:
  /// **'Successfully created block for collecting the pillar rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.'**
  String get pillarRewardsBlockCreated;

  /// No description provided for @pillarRewardsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays a chart with your Pillar rewards. Pillar rewards are generated either by operating a Pillar Node or from delegations to a Pillar Node'**
  String get pillarRewardsDescription;

  /// No description provided for @pillarRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pillar Rewards'**
  String get pillarRewardsTitle;

  /// No description provided for @pillarStats.
  ///
  /// In en, this message translates to:
  /// **'Pillar Stats'**
  String get pillarStats;

  /// No description provided for @pillarUpdate.
  ///
  /// In en, this message translates to:
  /// **'Pillar update'**
  String get pillarUpdate;

  /// No description provided for @pillarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Pillar updated'**
  String get pillarUpdated;

  /// No description provided for @pillars.
  ///
  /// In en, this message translates to:
  /// **'Pillars'**
  String get pillars;

  /// No description provided for @pillarsWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Pillars: {number}'**
  String pillarsWithNumber(Object number);

  /// No description provided for @pillarsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the number of active Pillars in the network'**
  String get pillarsDescription;

  /// No description provided for @pillarsListDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays Pillar Nodes that are currently active in the network. The list contains the name of the Pillar, the associated producer address, the weight (total number of delegations) and your delegation status. You can choose to delegate your {kZnnCoinSymbol} balance to any Pillar in order to receive delegation rewards in {kZnnCoinSymbol}. You can undelegate the balance at any time, without any penalties. Minimum delegation amount is 1 {kZnnCoinSymbol} per address'**
  String pillarsListDescription(Object kZnnCoinSymbol);

  /// No description provided for @pillarsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Pillars List'**
  String get pillarsListTitle;

  /// No description provided for @pillarsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pillars'**
  String get pillarsTitle;

  /// No description provided for @pressToReceive.
  ///
  /// In en, this message translates to:
  /// **'Press to receive the transaction'**
  String get pressToReceive;

  /// No description provided for @producerAddress.
  ///
  /// In en, this message translates to:
  /// **'Producer Address'**
  String get producerAddress;

  /// No description provided for @quasarTransactions.
  ///
  /// In en, this message translates to:
  /// **'{quasar} transactions'**
  String quasarTransactions(Object quasar);

  /// No description provided for @realtimeStats.
  ///
  /// In en, this message translates to:
  /// **'Realtime Stats'**
  String get realtimeStats;

  /// No description provided for @realtimeStatsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the number of {kZnnCoinSymbol} and {kQsrCoinSymbol} transactions. For example, a delegation is considered a {kZnnCoinSymbol} transaction from the network\'s perspective. Every interaction with the network embedded contracts is internally considered a transaction'**
  String realtimeStatsDescription(Object kQsrCoinSymbol, Object kZnnCoinSymbol);

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @recipientAddress.
  ///
  /// In en, this message translates to:
  /// **'Recipient Address'**
  String get recipientAddress;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerAnotherPillar.
  ///
  /// In en, this message translates to:
  /// **'Register another Pillar'**
  String get registerAnotherPillar;

  /// No description provided for @registerPillar.
  ///
  /// In en, this message translates to:
  /// **'Register Pillar'**
  String get registerPillar;

  /// No description provided for @registeredUse.
  ///
  /// In en, this message translates to:
  /// **' registered. Use '**
  String get registeredUse;

  /// No description provided for @requiredForPillarSlot.
  ///
  /// In en, this message translates to:
  /// **'{coins} {kQsrCoinSymbol} required for a Pillar slot'**
  String requiredForPillarSlot(Object coins, Object kQsrCoinSymbol);

  /// No description provided for @revocationWindowOpen.
  ///
  /// In en, this message translates to:
  /// **'Revocation window is open'**
  String get revocationWindowOpen;

  /// No description provided for @sAgo.
  ///
  /// In en, this message translates to:
  /// **'s ago'**
  String get sAgo;

  /// No description provided for @saveQr.
  ///
  /// In en, this message translates to:
  /// **'Save QR'**
  String get saveQr;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendTransaction.
  ///
  /// In en, this message translates to:
  /// **'send transaction'**
  String get sendTransaction;

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @senderAddressDescription.
  ///
  /// In en, this message translates to:
  /// **'The address from which the transaction will be sent'**
  String get senderAddressDescription;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @sentDetails.
  ///
  /// In en, this message translates to:
  /// **'Sent {amount} {symbol} from {sender} to {recipient}'**
  String sentDetails(
    Object amount,
    Object recipient,
    Object sender,
    Object symbol,
  );

  /// No description provided for @sentinelCollectDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays your current Sentinel rewards that are ready to be collected. If there are any rewards available, you will be able to collect them. In order to receive rewards, the Sentinel Node needs to be not only registered in the network, but also deployed (use znn-controller for this operation) and it must have >90% daily uptime'**
  String get sentinelCollectDescription;

  /// No description provided for @sentinelCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Sentinel Collect'**
  String get sentinelCollectTitle;

  /// No description provided for @sentinelRewardsBlockCreated.
  ///
  /// In en, this message translates to:
  /// **'Successfully created block for collecting the sentinel rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.'**
  String get sentinelRewardsBlockCreated;

  /// No description provided for @sentinels.
  ///
  /// In en, this message translates to:
  /// **'Sentinels'**
  String get sentinels;

  /// No description provided for @sentinelsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the number of active Sentinels in the network'**
  String get sentinelsDescription;

  /// No description provided for @shareQr.
  ///
  /// In en, this message translates to:
  /// **'Share QR'**
  String get shareQr;

  /// No description provided for @spawn.
  ///
  /// In en, this message translates to:
  /// **'Spawn'**
  String get spawn;

  /// No description provided for @stakingStats.
  ///
  /// In en, this message translates to:
  /// **'Staking Stats'**
  String get stakingStats;

  /// No description provided for @stakingStatsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the number of staking entries and the total {kZnnCoinSymbol} that you are currently staking'**
  String stakingStatsDescription(Object kZnnCoinSymbol);

  /// No description provided for @successfully.
  ///
  /// In en, this message translates to:
  /// **'successfully'**
  String get successfully;

  /// No description provided for @sufficientPlasma.
  ///
  /// In en, this message translates to:
  /// **'Sufficient Plasma'**
  String get sufficientPlasma;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @tokenTransactions.
  ///
  /// In en, this message translates to:
  /// **'Token Transactions'**
  String get tokenTransactions;

  /// No description provided for @transactionError.
  ///
  /// In en, this message translates to:
  /// **'Error while receiving transaction'**
  String get transactionError;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @transactionsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays the total number of transactions settled in the last hour across the network'**
  String get transactionsDescription;

  /// No description provided for @transactionsLastHour.
  ///
  /// In en, this message translates to:
  /// **'transactions in the last hour'**
  String get transactionsLastHour;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferDescription.
  ///
  /// In en, this message translates to:
  /// **'Redirects you to the Transfer tab where you can manage sending and receiving funds'**
  String get transferDescription;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @undelegate.
  ///
  /// In en, this message translates to:
  /// **'UNDELEGATE'**
  String get undelegate;

  /// No description provided for @untilRevocationWindowOpens.
  ///
  /// In en, this message translates to:
  /// **'Until revocation window opens'**
  String get untilRevocationWindowOpens;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updatePillar.
  ///
  /// In en, this message translates to:
  /// **'Update Pillar'**
  String get updatePillar;

  /// No description provided for @updatePillarSettings.
  ///
  /// In en, this message translates to:
  /// **'Update Pillar settings'**
  String get updatePillarSettings;

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get uptime;

  /// No description provided for @usDateFormat.
  ///
  /// In en, this message translates to:
  /// **'MM/dd/yyyy'**
  String get usDateFormat;

  /// No description provided for @viewPillars.
  ///
  /// In en, this message translates to:
  /// **'View Pillars'**
  String get viewPillars;

  /// No description provided for @waitingForDataFetching.
  ///
  /// In en, this message translates to:
  /// **'Waiting for data fetching'**
  String get waitingForDataFetching;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @youHaveDeposited.
  ///
  /// In en, this message translates to:
  /// **'You have deposited {coins} {kQsrCoinSymbol}'**
  String youHaveDeposited(Object coins, Object kQsrCoinSymbol);

  /// No description provided for @zenonTransactions.
  ///
  /// In en, this message translates to:
  /// **'{zenon} transactions'**
  String zenonTransactions(Object zenon);

  /// No description provided for @znnController.
  ///
  /// In en, this message translates to:
  /// **'znn-controller '**
  String get znnController;

  /// No description provided for @ztsSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Coins and tokens can be searched by name - \"Zenon\" -, by symbol - \"ZNN\" -, and by token standard - \"zts1znnxxxxxxxxxxxxx9z4ulx\"'**
  String get ztsSearchDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
