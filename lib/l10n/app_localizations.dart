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

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @abstain.
  ///
  /// In en, this message translates to:
  /// **'Abstain'**
  String get abstain;

  /// No description provided for @acceleratorAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Accelerator available balance'**
  String get acceleratorAvailableBalance;

  /// No description provided for @acceleratorDonations.
  ///
  /// In en, this message translates to:
  /// **'Accelerator Donations'**
  String get acceleratorDonations;

  /// No description provided for @acceleratorFundEmpty.
  ///
  /// In en, this message translates to:
  /// **'Accelerator fund empty'**
  String get acceleratorFundEmpty;

  /// No description provided for @acceleratorStats.
  ///
  /// In en, this message translates to:
  /// **'Accelerator Stats'**
  String get acceleratorStats;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @acknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get acknowledged;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

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

  /// No description provided for @activeSwap.
  ///
  /// In en, this message translates to:
  /// **'Active swap'**
  String get activeSwap;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressOwnsOrProducesNoPillar.
  ///
  /// In en, this message translates to:
  /// **'This address owns or produces no pillar'**
  String get addressOwnsOrProducesNoPillar;

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

  /// No description provided for @allDonatedFundsGoToAccelerator.
  ///
  /// In en, this message translates to:
  /// **'All donated funds go directly into the Accelerator address'**
  String get allDonatedFundsGoToAccelerator;

  /// No description provided for @alreadyVoted.
  ///
  /// In en, this message translates to:
  /// **'Already voted'**
  String get alreadyVoted;

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

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @balanceUnavailableForAddress.
  ///
  /// In en, this message translates to:
  /// **'Balance is unavailable for the selected address'**
  String get balanceUnavailableForAddress;

  /// No description provided for @beneficiaryAddress.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary address'**
  String get beneficiaryAddress;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cannotJoinSwapExpiresTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Cannot join swap. The swap will expire too soon for a safe swap.'**
  String get cannotJoinSwapExpiresTooSoon;

  /// No description provided for @cancelPlasmaConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the Plasma fusion?'**
  String get cancelPlasmaConfirmation;

  /// No description provided for @checkPillarStatus.
  ///
  /// In en, this message translates to:
  /// **' to check the Pillar status'**
  String get checkPillarStatus;

  /// No description provided for @checkSentinelStatus.
  ///
  /// In en, this message translates to:
  /// **' to check the Sentinel status'**
  String get checkSentinelStatus;

  /// No description provided for @checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check update'**
  String get checkUpdate;

  /// No description provided for @checkUpdatesForSyriusWallet.
  ///
  /// In en, this message translates to:
  /// **'Check updates for the Syrius wallet'**
  String get checkUpdatesForSyriusWallet;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get clearAllNotifications;

  /// No description provided for @clickToAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Click to add to favorites'**
  String get clickToAddToFavorites;

  /// No description provided for @clickToRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Click to remove from favorites'**
  String get clickToRemoveFromFavorites;

  /// No description provided for @clientChainIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Client chain identifier'**
  String get clientChainIdentifier;

  /// No description provided for @clientHostname.
  ///
  /// In en, this message translates to:
  /// **'Client hostname'**
  String get clientHostname;

  /// No description provided for @clientLocalIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Client local IP address'**
  String get clientLocalIpAddress;

  /// No description provided for @clientNumberOfProcessors.
  ///
  /// In en, this message translates to:
  /// **'Client number of processors'**
  String get clientNumberOfProcessors;

  /// No description provided for @clientOperatingSystem.
  ///
  /// In en, this message translates to:
  /// **'Client operating system'**
  String get clientOperatingSystem;

  /// No description provided for @clientOperatingSystemVersion.
  ///
  /// In en, this message translates to:
  /// **'Client operating system version'**
  String get clientOperatingSystemVersion;

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

  /// No description provided for @collectStakingRewards.
  ///
  /// In en, this message translates to:
  /// **'Collect staking rewards'**
  String get collectStakingRewards;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @cannotReuseAddressForSentinel.
  ///
  /// In en, this message translates to:
  /// **'If this address previously revoked a Sentinel, it cannot create a new Sentinel again. Use a different address before depositing QSR.'**
  String get cannotReuseAddressForSentinel;

  /// No description provided for @consumeZnnToSubmitProject.
  ///
  /// In en, this message translates to:
  /// **'Consume {amount} {symbol} to submit the project'**
  String consumeZnnToSubmitProject(String amount, String symbol);

  /// No description provided for @couldNotSend.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send {amount} {symbol} to {recipient}'**
  String couldNotSend(Object amount, Object recipient, Object symbol);

  /// No description provided for @burn.
  ///
  /// In en, this message translates to:
  /// **'Burn'**
  String get burn;

  /// No description provided for @burnableToken.
  ///
  /// In en, this message translates to:
  /// **'Burnable by any holder'**
  String get burnableToken;

  /// No description provided for @burnTokenIssueFee.
  ///
  /// In en, this message translates to:
  /// **'You will need to burn {amount} {symbol} to issue a token'**
  String burnTokenIssueFee(Object amount, Object symbol);

  /// No description provided for @cameraQrScanner.
  ///
  /// In en, this message translates to:
  /// **'Camera QR Scanner'**
  String get cameraQrScanner;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @copyDepositId.
  ///
  /// In en, this message translates to:
  /// **'Copy deposit ID'**
  String get copyDepositId;

  /// No description provided for @counterpartyAddress.
  ///
  /// In en, this message translates to:
  /// **'Counterparty address'**
  String get counterpartyAddress;

  /// No description provided for @counterpartyDepositId.
  ///
  /// In en, this message translates to:
  /// **'Counterparty deposit ID'**
  String get counterpartyDepositId;

  /// Explains how many hours the counterparty has to complete a swap.
  ///
  /// In en, this message translates to:
  /// **'The counterparty will have <highlight>~{hours} hour</highlight> to complete the swap.'**
  String counterpartyTimeToCompleteSwap(int hours);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createAnotherPhase.
  ///
  /// In en, this message translates to:
  /// **'Create another phase'**
  String get createAnotherPhase;

  /// No description provided for @createAnotherProject.
  ///
  /// In en, this message translates to:
  /// **'Create another project'**
  String get createAnotherProject;

  /// No description provided for @createAnotherToken.
  ///
  /// In en, this message translates to:
  /// **'Create another Token'**
  String get createAnotherToken;

  /// No description provided for @createdWithDate.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String createdWithDate(String date);

  /// No description provided for @createPhase.
  ///
  /// In en, this message translates to:
  /// **'Create phase'**
  String get createPhase;

  /// No description provided for @createPhaseForYourProject.
  ///
  /// In en, this message translates to:
  /// **'Create a phase for your project. The project can be divided into several phases. You will unlock the funds if you get enough votes from the Pillars.'**
  String get createPhaseForYourProject;

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

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProject;

  /// No description provided for @createSentinelDescription.
  ///
  /// In en, this message translates to:
  /// **'Start the process of deploying a Sentinel Node in the network'**
  String get createSentinelDescription;

  /// No description provided for @createStake.
  ///
  /// In en, this message translates to:
  /// **'create stake'**
  String get createStake;

  /// No description provided for @createStakeDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays information about staking per wallet address. Choose the duration and the amount in {kZnnCoinSymbol} for staking in order to receive {kQsrCoinSymbol}'**
  String createStakeDescription(Object kQsrCoinSymbol, Object kZnnCoinSymbol);

  /// No description provided for @createStakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Stake'**
  String get createStakeTitle;

  /// No description provided for @createToken.
  ///
  /// In en, this message translates to:
  /// **'Create Token'**
  String get createToken;

  /// No description provided for @createTokenDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a token following the ZTS specification'**
  String get createTokenDescription;

  /// No description provided for @createTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Token'**
  String get createTokenTitle;

  /// No description provided for @creatingProjectConsumesZnn.
  ///
  /// In en, this message translates to:
  /// **'Creating a project consumes {amount} {symbol} that goes to the Accelerator'**
  String creatingProjectConsumesZnn(String amount, String symbol);

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

  /// No description provided for @currentSentinelSlotFee.
  ///
  /// In en, this message translates to:
  /// **'Current Sentinel Slot fee\n{coins} {kQsrCoinSymbol}'**
  String currentSentinelSlotFee(Object coins, Object kQsrCoinSymbol);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// No description provided for @decimals.
  ///
  /// In en, this message translates to:
  /// **'{number} decimals'**
  String decimals(Object number);

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

  /// No description provided for @depositExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Deposit expires in'**
  String get depositExpiresIn;

  /// No description provided for @depositId.
  ///
  /// In en, this message translates to:
  /// **'Deposit ID'**
  String get depositId;

  /// No description provided for @depositIdProvidedByCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Deposit ID provided by the counterparty'**
  String get depositIdProvidedByCounterparty;

  /// No description provided for @deposited.
  ///
  /// In en, this message translates to:
  /// **'{kQsrCoinSymbol} deposited'**
  String deposited(Object kQsrCoinSymbol);

  /// No description provided for @depositedAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposited amount'**
  String get depositedAmount;

  /// No description provided for @depositedAmountReclaimed.
  ///
  /// In en, this message translates to:
  /// **'Deposited amount (reclaimed)'**
  String get depositedAmountReclaimed;

  /// No description provided for @depositedCoinWillBurn.
  ///
  /// In en, this message translates to:
  /// **'All the deposited {kQsrCoinSymbol} will be burned in order to create the Pillar Slot'**
  String depositedCoinWillBurn(Object kQsrCoinSymbol);

  /// No description provided for @deleteAllNotificationsCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications? This action cannot be undone.'**
  String get deleteAllNotificationsCannotBeUndone;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get deleteNotification;

  /// No description provided for @deleteSwap.
  ///
  /// In en, this message translates to:
  /// **'Delete swap'**
  String get deleteSwap;

  /// No description provided for @deleteSwapCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this swap? This action cannot be undone.'**
  String get deleteSwapCannotBeUndone;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @detailedInfoAboutWalletComponents.
  ///
  /// In en, this message translates to:
  /// **'Detailed information about wallet components'**
  String get detailedInfoAboutWalletComponents;

  /// No description provided for @detailedInfoAboutYourProject.
  ///
  /// In en, this message translates to:
  /// **'Detailed information about your project'**
  String get detailedInfoAboutYourProject;

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

  /// No description provided for @disassembleSentinelToUnlockCoin.
  ///
  /// In en, this message translates to:
  /// **'You will be able to unlock the {kZnnCoinSymbol} if you choose to disassemble the Sentinel'**
  String disassembleSentinelToUnlockCoin(Object kZnnCoinSymbol);

  /// No description provided for @displaysWalletNotificationsDetails.
  ///
  /// In en, this message translates to:
  /// **'This card displays detailed information regarding the wallet notifications'**
  String get displaysWalletNotificationsDetails;

  /// No description provided for @displaysZenonCommunityResources.
  ///
  /// In en, this message translates to:
  /// **'This card displays information about Zenon community resources'**
  String get displaysZenonCommunityResources;

  /// No description provided for @documentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// No description provided for @donate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// No description provided for @donationAddress.
  ///
  /// In en, this message translates to:
  /// **'Donation address'**
  String get donationAddress;

  /// No description provided for @donationAmountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Donation amount must be greater than zero'**
  String get donationAmountMustBePositive;

  /// No description provided for @donationDetails.
  ///
  /// In en, this message translates to:
  /// **'Donation details'**
  String get donationDetails;

  /// No description provided for @donationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Donation submitted'**
  String get donationSubmitted;

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

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @eachProjectComprisedOfPhases.
  ///
  /// In en, this message translates to:
  /// **'Each project can be comprised of one or more phases. Each phase needs to be voted. Phases can be updated by the owner of the project to reflect current progress of the project.'**
  String get eachProjectComprisedOfPhases;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @enterValidDomainWithoutProtocol.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid domain without protocol (e.g. example.com)'**
  String get enterValidDomainWithoutProtocol;

  /// No description provided for @errorCreatingPhase.
  ///
  /// In en, this message translates to:
  /// **'Error while creating phase'**
  String get errorCreatingPhase;

  /// No description provided for @errorGettingVoteBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Error while trying to get the vote breakdown'**
  String get errorGettingVoteBreakdown;

  /// No description provided for @errorSubmittingDonation.
  ///
  /// In en, this message translates to:
  /// **'Error while submitting donation'**
  String get errorSubmittingDonation;

  /// No description provided for @errorSubmittingProject.
  ///
  /// In en, this message translates to:
  /// **'Error while submitting project'**
  String get errorSubmittingProject;

  /// No description provided for @errorUpdatingPhase.
  ///
  /// In en, this message translates to:
  /// **'Error while updating phase'**
  String get errorUpdatingPhase;

  /// No description provided for @errorVotingProject.
  ///
  /// In en, this message translates to:
  /// **'Error while voting project'**
  String get errorVotingProject;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRate;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorClearingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error while clearing notifications'**
  String get errorClearingNotifications;

  /// No description provided for @errorCreatingToken.
  ///
  /// In en, this message translates to:
  /// **'Error while creating a new ZTS token'**
  String get errorCreatingToken;

  /// No description provided for @errorAddingTokenToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error adding {name} token to favorites'**
  String errorAddingTokenToFavorites(Object name);

  /// No description provided for @errorBurningZts.
  ///
  /// In en, this message translates to:
  /// **'Error while trying to burn ZTS'**
  String get errorBurningZts;

  /// No description provided for @errorCompletingSwap.
  ///
  /// In en, this message translates to:
  /// **'Error while completing swap'**
  String get errorCompletingSwap;

  /// No description provided for @errorDeletingNotification.
  ///
  /// In en, this message translates to:
  /// **'Error while deleting notification'**
  String get errorDeletingNotification;

  /// No description provided for @errorDeletingSwap.
  ///
  /// In en, this message translates to:
  /// **'Error while deleting swap'**
  String get errorDeletingSwap;

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

  /// No description provided for @errorDeployingSentinel.
  ///
  /// In en, this message translates to:
  /// **'Error while deploying the Sentinel Node'**
  String get errorDeployingSentinel;

  /// No description provided for @errorDisassemblingPillar.
  ///
  /// In en, this message translates to:
  /// **'Error while disassembling Pillar'**
  String get errorDisassemblingPillar;

  /// No description provided for @errorDisassemblingSentinel.
  ///
  /// In en, this message translates to:
  /// **'Error while disassembling Sentinel'**
  String get errorDisassemblingSentinel;

  /// No description provided for @errorCollectingStakingRewards.
  ///
  /// In en, this message translates to:
  /// **'Error while collecting staking rewards'**
  String get errorCollectingStakingRewards;

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

  /// No description provided for @errorWhileCancellingPlasma.
  ///
  /// In en, this message translates to:
  /// **'Error while cancelling Plasma'**
  String get errorWhileCancellingPlasma;

  /// No description provided for @errorWhileCancellingStake.
  ///
  /// In en, this message translates to:
  /// **'Error while cancelling stake'**
  String get errorWhileCancellingStake;

  /// No description provided for @errorWhileDeactivatingPairing.
  ///
  /// In en, this message translates to:
  /// **'Error while deactivating pairing'**
  String get errorWhileDeactivatingPairing;

  /// No description provided for @errorWhileDisconnectingSession.
  ///
  /// In en, this message translates to:
  /// **'Error while disconnecting session'**
  String get errorWhileDisconnectingSession;

  /// No description provided for @errorGeneratingPlasma.
  ///
  /// In en, this message translates to:
  /// **'Error while generating Plasma'**
  String get errorGeneratingPlasma;

  /// No description provided for @errorMintingToken.
  ///
  /// In en, this message translates to:
  /// **'Error while trying to mint {symbol}'**
  String errorMintingToken(Object symbol);

  /// No description provided for @errorJoiningSwap.
  ///
  /// In en, this message translates to:
  /// **'Error while joining swap'**
  String get errorJoiningSwap;

  /// No description provided for @errorReclaimingDeposit.
  ///
  /// In en, this message translates to:
  /// **'Error while reclaiming deposit'**
  String get errorReclaimingDeposit;

  /// No description provided for @errorRemovingTokenFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error removing {name} token from favorites'**
  String errorRemovingTokenFromFavorites(Object name);

  /// No description provided for @errorTransferringTokenOwnership.
  ///
  /// In en, this message translates to:
  /// **'Error while trying to transfer token ownership'**
  String get errorTransferringTokenOwnership;

  /// No description provided for @errorWhileDepositing.
  ///
  /// In en, this message translates to:
  /// **'Error while depositing {kQsrCoinSymbol}'**
  String errorWhileDepositing(Object kQsrCoinSymbol);

  /// No description provided for @errorWhileGeneratingStake.
  ///
  /// In en, this message translates to:
  /// **'Error while generating stake'**
  String get errorWhileGeneratingStake;

  /// No description provided for @errorStartingSwap.
  ///
  /// In en, this message translates to:
  /// **'Error while starting swap'**
  String get errorStartingSwap;

  /// No description provided for @errorWhileWithdrawing.
  ///
  /// In en, this message translates to:
  /// **'Error while withdrawing {kQsrCoinSymbol}'**
  String errorWhileWithdrawing(Object kQsrCoinSymbol);

  /// No description provided for @expiration.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get expiration;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get expiresIn;

  /// No description provided for @expectedProducedMomentums.
  ///
  /// In en, this message translates to:
  /// **'Expected/produced momentums'**
  String get expectedProducedMomentums;

  /// No description provided for @explorers.
  ///
  /// In en, this message translates to:
  /// **'Explorers'**
  String get explorers;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @fuelForTheMothership.
  ///
  /// In en, this message translates to:
  /// **'Fuel for the Mothership'**
  String get fuelForTheMothership;

  /// No description provided for @fuse.
  ///
  /// In en, this message translates to:
  /// **'Fuse'**
  String get fuse;

  /// No description provided for @fusePlasmaDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays information about Plasma available per wallet address. A minimum of 10 {kQsrCoinSymbol} are needed to be fused in order to generate Plasma. The more {kQsrCoinSymbol} fused, the more Plasma is produced for the beneficiary address\n\nInsufficient Plasma: Proof-of-work for Plasma generation; limited to 1 transaction per momentum\nLow Plasma: between 10 and 89 {kQsrCoinSymbol}\nAverage Plasma: between 90 and 119 {kQsrCoinSymbol}\nHigh Plasma: over 120 {kQsrCoinSymbol}; recommended for complex transactions (register Pillars, Sentinels, staking and issuing ZTS tokens)'**
  String fusePlasmaDescription(Object kQsrCoinSymbol);

  /// No description provided for @fusePlasmaTitle.
  ///
  /// In en, this message translates to:
  /// **'Fuse Plasma'**
  String get fusePlasmaTitle;

  /// No description provided for @fusedPlasmaDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays all your addresses that have Plasma generated by fusing {kQsrCoinSymbol}'**
  String fusedPlasmaDescription(Object kQsrCoinSymbol);

  /// No description provided for @fusedPlasmaTitle.
  ///
  /// In en, this message translates to:
  /// **'Fused Plasma'**
  String get fusedPlasmaTitle;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @hash.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get hash;

  /// No description provided for @hashlock.
  ///
  /// In en, this message translates to:
  /// **'Hashlock'**
  String get hashlock;

  /// No description provided for @hashValue.
  ///
  /// In en, this message translates to:
  /// **'Hash: {value}'**
  String hashValue(Object value);

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get hideDetails;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String hoursAgo(int count);

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String hoursCount(int count);

  /// No description provided for @idWithValue.
  ///
  /// In en, this message translates to:
  /// **'ID {id}'**
  String idWithValue(String id);

  /// No description provided for @innovateInspireBuild.
  ///
  /// In en, this message translates to:
  /// **'Innovate. Inspire. Build.'**
  String get innovateInspireBuild;

  /// No description provided for @inputAmountToSend.
  ///
  /// In en, this message translates to:
  /// **'Input an amount to send'**
  String get inputAmountToSend;

  /// No description provided for @inputDepositId.
  ///
  /// In en, this message translates to:
  /// **'Input the deposit ID'**
  String get inputDepositId;

  /// No description provided for @inputtedNumberHasTooManyDecimals.
  ///
  /// In en, this message translates to:
  /// **'Inputted number has too many decimals'**
  String get inputtedNumberHasTooManyDecimals;

  /// No description provided for @invalidQrCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get invalidQrCode;

  /// No description provided for @invalidQrCodeException.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code exception'**
  String get invalidQrCodeException;

  /// No description provided for @issueToken.
  ///
  /// In en, this message translates to:
  /// **'Issue Token'**
  String get issueToken;

  /// No description provided for @joinSwap.
  ///
  /// In en, this message translates to:
  /// **'Join swap'**
  String get joinSwap;

  /// No description provided for @joinTheAliensBuildingNom.
  ///
  /// In en, this message translates to:
  /// **'Join the Aliens building the future on Network of Momentum'**
  String get joinTheAliensBuildingNom;

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

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @linkToProjectArticle.
  ///
  /// In en, this message translates to:
  /// **'Link to project article'**
  String get linkToProjectArticle;

  /// No description provided for @listContainsAllProjects.
  ///
  /// In en, this message translates to:
  /// **'This card displays a list that contains all the projects'**
  String get listContainsAllProjects;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'{kQsrCoinSymbol} locked'**
  String locked(Object kQsrCoinSymbol);

  /// No description provided for @localTimeDiscrepancyDetected.
  ///
  /// In en, this message translates to:
  /// **'Local time discrepancy detected. Please confirm your operating system\'s time is correct before conducting P2P swaps.'**
  String get localTimeDiscrepancyDetected;

  /// No description provided for @makeAnotherDonation.
  ///
  /// In en, this message translates to:
  /// **'Make another donation'**
  String get makeAnotherDonation;

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

  /// No description provided for @maxSupply.
  ///
  /// In en, this message translates to:
  /// **'Max supply'**
  String get maxSupply;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesCount(int count);

  /// Explains how many minutes remain to join a swap.
  ///
  /// In en, this message translates to:
  /// **'You have <highlight>{minutes} minutes</highlight> left to join the swap.'**
  String minutesLeftToJoinSwap(int minutes);

  /// No description provided for @mint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get mint;

  /// No description provided for @mintable.
  ///
  /// In en, this message translates to:
  /// **'Mintable'**
  String get mintable;

  /// No description provided for @mintableToken.
  ///
  /// In en, this message translates to:
  /// **'Mintable token'**
  String get mintableToken;

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

  /// No description provided for @moreVotesNeededForQuorum.
  ///
  /// In en, this message translates to:
  /// **'{count} more votes needed to achieve quorum'**
  String moreVotesNeededForQuorum(int count);

  /// No description provided for @moreYesThanNoVotes.
  ///
  /// In en, this message translates to:
  /// **'More yes than no votes'**
  String get moreYesThanNoVotes;

  /// No description provided for @myProjects.
  ///
  /// In en, this message translates to:
  /// **'My projects'**
  String get myProjects;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @necessaryBudgetToCompletePhase.
  ///
  /// In en, this message translates to:
  /// **'Necessary budget to successfully complete this phase'**
  String get necessaryBudgetToCompletePhase;

  /// No description provided for @needsVoting.
  ///
  /// In en, this message translates to:
  /// **'Needs voting'**
  String get needsVoting;

  /// No description provided for @newOwnerAddress.
  ///
  /// In en, this message translates to:
  /// **'New owner address'**
  String get newOwnerAddress;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get no;

  /// No description provided for @noActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'No active projects'**
  String get noActiveProjects;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items founds'**
  String get noItemsFound;

  /// No description provided for @noMatchingPhases.
  ///
  /// In en, this message translates to:
  /// **'No matching phases found'**
  String get noMatchingPhases;

  /// No description provided for @noMoreItems.
  ///
  /// In en, this message translates to:
  /// **'No more items'**
  String get noMoreItems;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @noP2pSwaps.
  ///
  /// In en, this message translates to:
  /// **'No P2P swaps'**
  String get noP2pSwaps;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get noProjectsFound;

  /// No description provided for @noRewardsCollect.
  ///
  /// In en, this message translates to:
  /// **'No rewards to collect'**
  String get noRewardsCollect;

  /// No description provided for @notEnoughYesVotes.
  ///
  /// In en, this message translates to:
  /// **'Not enough yes votes'**
  String get notEnoughYesVotes;

  /// No description provided for @noVotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} No votes'**
  String noVotesCount(int count);

  /// No description provided for @noZtsTokensAvailable.
  ///
  /// In en, this message translates to:
  /// **'No ZTS tokens available'**
  String get noZtsTokensAvailable;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @numberOfDecimals.
  ///
  /// In en, this message translates to:
  /// **'Number of decimals: {number}'**
  String numberOfDecimals(Object number);

  /// No description provided for @oldestSwapDeletedWhenFull.
  ///
  /// In en, this message translates to:
  /// **'The oldest swap entry will be deleted when a new swap is started.'**
  String get oldestSwapDeletedWhenFull;

  /// No description provided for @onScreenQrScanner.
  ///
  /// In en, this message translates to:
  /// **'On-screen QR Scanner'**
  String get onScreenQrScanner;

  /// No description provided for @onlyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Only accepted'**
  String get onlyAccepted;

  /// No description provided for @onlyMacOsSupported.
  ///
  /// In en, this message translates to:
  /// **'Only macOS is supported at the moment'**
  String get onlyMacOsSupported;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @ownerWithAddress.
  ///
  /// In en, this message translates to:
  /// **'Owner {address}'**
  String ownerWithAddress(String address);

  /// No description provided for @ownZtsToken.
  ///
  /// In en, this message translates to:
  /// **'You own this ZTS token'**
  String get ownZtsToken;

  /// No description provided for @p2pSwapAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter NoM address'**
  String get p2pSwapAddressHint;

  /// No description provided for @p2pSwapCounterpartyAddressDescription.
  ///
  /// In en, this message translates to:
  /// **'The address of the trading partner for the swap.'**
  String get p2pSwapCounterpartyAddressDescription;

  /// No description provided for @p2pSwapFillDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in the swap details'**
  String get p2pSwapFillDetails;

  /// No description provided for @p2pSwapGeneratingPlasma.
  ///
  /// In en, this message translates to:
  /// **'Please wait while Plasma is generated'**
  String get p2pSwapGeneratingPlasma;

  /// No description provided for @p2pSwapHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String p2pSwapHours(Object hours);

  /// No description provided for @p2pSwapJoinDescription.
  ///
  /// In en, this message translates to:
  /// **'Join a native swap started by a counterparty.'**
  String get p2pSwapJoinDescription;

  /// No description provided for @p2pSwapMachineOnly.
  ///
  /// In en, this message translates to:
  /// **'The swap must be completed on this machine.'**
  String get p2pSwapMachineOnly;

  /// No description provided for @p2pSwapOptionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Starting and joining P2P swaps can be done from this card.'**
  String get p2pSwapOptionsDescription;

  /// No description provided for @p2pSwapOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'P2P Swap Options'**
  String get p2pSwapOptionsTitle;

  /// No description provided for @p2pSwapOwnAddressError.
  ///
  /// In en, this message translates to:
  /// **'Cannot swap with your own address'**
  String get p2pSwapOwnAddressError;

  /// Explains when the user can reclaim funds if the counterparty does not join the swap.
  ///
  /// In en, this message translates to:
  /// **'You can reclaim your funds in <highlight>{duration}</highlight> if the counterparty fails to join the swap.'**
  String p2pSwapReclaimFunds(String duration);

  /// No description provided for @p2pSwapStart.
  ///
  /// In en, this message translates to:
  /// **'Start swap'**
  String get p2pSwapStart;

  /// No description provided for @p2pSwapStartDescription.
  ///
  /// In en, this message translates to:
  /// **'Start a native swap with a counterparty.'**
  String get p2pSwapStartDescription;

  /// No description provided for @p2pSwapWaitForCounterparty.
  ///
  /// In en, this message translates to:
  /// **'After starting the swap, wait for the counterparty to join the swap with the agreed upon amount.'**
  String get p2pSwapWaitForCounterparty;

  /// No description provided for @p2pSwapWarningDescription.
  ///
  /// In en, this message translates to:
  /// **'Please note that the P2P swap is an experimental feature and may result in funds being lost.\n\nUse the feature with caution and consider splitting large swaps into multiple smaller ones.'**
  String get p2pSwapWarningDescription;

  /// No description provided for @p2pSwapWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Before continuing'**
  String get p2pSwapWarningTitle;

  /// No description provided for @p2pSwaps.
  ///
  /// In en, this message translates to:
  /// **'P2P Swaps'**
  String get p2pSwaps;

  /// No description provided for @p2pSwapsConductedWithWallet.
  ///
  /// In en, this message translates to:
  /// **'This card displays a list of P2P swaps that have been conducted with this wallet.'**
  String get p2pSwapsConductedWithWallet;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @pairingTopic.
  ///
  /// In en, this message translates to:
  /// **'Pairing Topic'**
  String get pairingTopic;

  /// No description provided for @pairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get pairingFailed;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pasteWalletConnectLinkHere.
  ///
  /// In en, this message translates to:
  /// **'Paste the WalletConnect link here'**
  String get pasteWalletConnectLinkHere;

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

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get permissionRequired;

  /// No description provided for @phaseBelongsToProject.
  ///
  /// In en, this message translates to:
  /// **'This phase belongs to Project ID {projectId}'**
  String phaseBelongsToProject(String projectId);

  /// No description provided for @phaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Phase description'**
  String get phaseDescription;

  /// No description provided for @phaseDetails.
  ///
  /// In en, this message translates to:
  /// **'Phase details'**
  String get phaseDetails;

  /// No description provided for @phaseList.
  ///
  /// In en, this message translates to:
  /// **'Phase List'**
  String get phaseList;

  /// No description provided for @phaseName.
  ///
  /// In en, this message translates to:
  /// **'Phase name'**
  String get phaseName;

  /// No description provided for @phaseNeedsVoting.
  ///
  /// In en, this message translates to:
  /// **'Phase needs voting'**
  String get phaseNeedsVoting;

  /// No description provided for @phaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Phase URL'**
  String get phaseUrl;

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

  /// No description provided for @pillarsCanStillVote.
  ///
  /// In en, this message translates to:
  /// **'{count} Pillars that can still cast a vote'**
  String pillarsCanStillVote(int count);

  /// No description provided for @plasmaStatsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays information about current Plasma level for each wallet address. Plasma is used as an anti-spam mechanism. More Plasma you have per address, more transactions you will be able to send or receive on that address. Low or insufficient Plasma will require proof-of-work for generation. Fuse 10 {kQsrCoinSymbol} or more in order to obtain Plasma for any given address\n\nInsufficient Plasma: Proof-of-work for Plasma generation; limited to 1 transaction per momentum\nLow Plasma: between 10 and 50 {kQsrCoinSymbol}\nAverage Plasma: between 50 and 119 {kQsrCoinSymbol}\nHigh Plasma: over 120 {kQsrCoinSymbol}; recommended to make complex transactions (deploy Pillars, Sentinels, staking and issuing ZTS tokens)'**
  String plasmaStatsDescription(Object kQsrCoinSymbol);

  /// No description provided for @plasmaStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Plasma Stats'**
  String get plasmaStatsTitle;

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

  /// No description provided for @plasma.
  ///
  /// In en, this message translates to:
  /// **'Plasma'**
  String get plasma;

  /// No description provided for @plasmaCheck.
  ///
  /// In en, this message translates to:
  /// **'Plasma Check'**
  String get plasmaCheck;

  /// No description provided for @pleaseScanValidWalletConnectQr.
  ///
  /// In en, this message translates to:
  /// **'Please scan a valid WalletConnect QR code'**
  String get pleaseScanValidWalletConnectQr;

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

  /// No description provided for @projectCreation.
  ///
  /// In en, this message translates to:
  /// **'Project creation'**
  String get projectCreation;

  /// No description provided for @projectDescription.
  ///
  /// In en, this message translates to:
  /// **'Project description'**
  String get projectDescription;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project details'**
  String get projectDetails;

  /// No description provided for @projectHasNoPhases.
  ///
  /// In en, this message translates to:
  /// **'The project has no phases'**
  String get projectHasNoPhases;

  /// No description provided for @projectList.
  ///
  /// In en, this message translates to:
  /// **'Project List'**
  String get projectList;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @projectStats.
  ///
  /// In en, this message translates to:
  /// **'Project Stats'**
  String get projectStats;

  /// No description provided for @projectSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Project submitted'**
  String get projectSubmitted;

  /// No description provided for @projectUrl.
  ///
  /// In en, this message translates to:
  /// **'Project URL'**
  String get projectUrl;

  /// No description provided for @qrCodeScanFailed.
  ///
  /// In en, this message translates to:
  /// **'QR code scan failed'**
  String get qrCodeScanFailed;

  /// No description provided for @qsrAmount.
  ///
  /// In en, this message translates to:
  /// **'QSR Amount'**
  String get qsrAmount;

  /// No description provided for @quasarTransactions.
  ///
  /// In en, this message translates to:
  /// **'{quasar} transactions'**
  String quasarTransactions(Object quasar);

  /// No description provided for @quorumAchieved.
  ///
  /// In en, this message translates to:
  /// **'Quorum achieved'**
  String get quorumAchieved;

  /// No description provided for @quorumNotAchieved.
  ///
  /// In en, this message translates to:
  /// **'Quorum not achieved'**
  String get quorumNotAchieved;

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

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @receivingWrongTokenOrAmount.
  ///
  /// In en, this message translates to:
  /// **'I\'m receiving the wrong token or amount.'**
  String get receivingWrongTokenOrAmount;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @recipientAddress.
  ///
  /// In en, this message translates to:
  /// **'Recipient Address'**
  String get recipientAddress;

  /// No description provided for @reclaimFunds.
  ///
  /// In en, this message translates to:
  /// **'Reclaim funds'**
  String get reclaimFunds;

  /// No description provided for @reclaimableFunds.
  ///
  /// In en, this message translates to:
  /// **'Reclaimable funds'**
  String get reclaimableFunds;

  /// No description provided for @reclaimFundsIfCounterpartyFails.
  ///
  /// In en, this message translates to:
  /// **'You can reclaim your funds if the counterparty fails to complete the swap.'**
  String get reclaimFundsIfCounterpartyFails;

  /// No description provided for @reclaimingFundsPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Reclaiming. This will take a moment.'**
  String get reclaimingFundsPleaseWait;

  /// No description provided for @receiveSwappedFundsToAddress.
  ///
  /// In en, this message translates to:
  /// **'You will receive the swapped funds to this address.'**
  String get receiveSwappedFundsToAddress;

  /// No description provided for @reclaimDeposit.
  ///
  /// In en, this message translates to:
  /// **'Reclaim deposit'**
  String get reclaimDeposit;

  /// No description provided for @reclaimExpiredDepositWithId.
  ///
  /// In en, this message translates to:
  /// **'If you have lost access to the machine that a swap was started on, the expired deposit can be reclaimed with the deposit ID.\n\nIf you don\'t have the deposit ID, please refer to the swap tutorial for instructions on how to find it using a block explorer.'**
  String get reclaimExpiredDepositWithId;

  /// No description provided for @reclaimTransactionSentFundsShortly.
  ///
  /// In en, this message translates to:
  /// **'Reclaim transaction sent. You will receive the funds shortly.'**
  String get reclaimTransactionSentFundsShortly;

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

  /// No description provided for @registerSentinel.
  ///
  /// In en, this message translates to:
  /// **'Register Sentinel'**
  String get registerSentinel;

  /// No description provided for @registeredUse.
  ///
  /// In en, this message translates to:
  /// **' registered. Use '**
  String get registeredUse;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @remainingBudgetForNextPhases.
  ///
  /// In en, this message translates to:
  /// **'Remaining budget for the next phases is {znnAmount} {znnSymbol} and {qsrAmount} {qsrSymbol}'**
  String remainingBudgetForNextPhases(
    String znnAmount,
    String znnSymbol,
    String qsrAmount,
    String qsrSymbol,
  );

  /// No description provided for @requiredForPillarSlot.
  ///
  /// In en, this message translates to:
  /// **'{coins} {kQsrCoinSymbol} required for a Pillar slot'**
  String requiredForPillarSlot(Object coins, Object kQsrCoinSymbol);

  /// No description provided for @requiredForSentinelNode.
  ///
  /// In en, this message translates to:
  /// **'{coins} {kQsrCoinSymbol} required for a Sentinel Node'**
  String requiredForSentinelNode(Object coins, Object kQsrCoinSymbol);

  /// No description provided for @returnToProjectList.
  ///
  /// In en, this message translates to:
  /// **'Return to project list'**
  String get returnToProjectList;

  /// No description provided for @revocationWindowOpen.
  ///
  /// In en, this message translates to:
  /// **'Revocation window is open'**
  String get revocationWindowOpen;

  /// No description provided for @saveQr.
  ///
  /// In en, this message translates to:
  /// **'Save QR'**
  String get saveQr;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @scanWalletConnectQrFromDapp.
  ///
  /// In en, this message translates to:
  /// **'Scan the WalletConnect QR from the dApp'**
  String get scanWalletConnectQrFromDapp;

  /// No description provided for @scanWalletConnectQrUsingCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan a WalletConnect QR code using the built-in camera of this device'**
  String get scanWalletConnectQrUsingCamera;

  /// No description provided for @scanWalletConnectQrUsingOnScreenScanner.
  ///
  /// In en, this message translates to:
  /// **'Scan the WalletConnect QR code using an on-screen QR scanner. This requires the screen recording permission'**
  String get scanWalletConnectQrUsingOnScreenScanner;

  /// No description provided for @screenRecordingPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Screen Recording permission is required to scan and process the on-screen WalletConnect QR code'**
  String get screenRecordingPermissionRequired;

  /// No description provided for @searchByIdNameDescriptionUrl.
  ///
  /// In en, this message translates to:
  /// **'Search by id, name, description, or URL'**
  String get searchByIdNameDescriptionUrl;

  /// No description provided for @searchByIdOwnerNameDescriptionUrl.
  ///
  /// In en, this message translates to:
  /// **'Search by id, owner, name, description, or URL'**
  String get searchByIdOwnerNameDescriptionUrl;

  /// No description provided for @searchTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, symbol, owner, or token standard'**
  String get searchTokenHint;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get searching;

  /// No description provided for @secondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} s ago'**
  String secondsAgo(int count);

  /// No description provided for @secondsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} s'**
  String secondsCount(int count);

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

  /// No description provided for @sentinel.
  ///
  /// In en, this message translates to:
  /// **'Sentinel'**
  String get sentinel;

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

  /// No description provided for @sendingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Sending transaction'**
  String get sendingTransaction;

  /// No description provided for @sentinelAddress.
  ///
  /// In en, this message translates to:
  /// **'Sentinel Address'**
  String get sentinelAddress;

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

  /// No description provided for @sentinelRewardsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays a chart with your Sentinel rewards from your Sentinel Node'**
  String get sentinelRewardsDescription;

  /// No description provided for @sentinelRewardsBlockCreated.
  ///
  /// In en, this message translates to:
  /// **'Successfully created block for collecting the sentinel rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.'**
  String get sentinelRewardsBlockCreated;

  /// No description provided for @sentinelRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sentinel Rewards'**
  String get sentinelRewardsTitle;

  /// No description provided for @sentinelDetectedOnThisAddress.
  ///
  /// In en, this message translates to:
  /// **'Sentinel detected on this address'**
  String get sentinelDetectedOnThisAddress;

  /// No description provided for @sentinelRegistered.
  ///
  /// In en, this message translates to:
  /// **'Sentinel registered'**
  String get sentinelRegistered;

  /// No description provided for @sentinelStats.
  ///
  /// In en, this message translates to:
  /// **'Sentinel Stats'**
  String get sentinelStats;

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

  /// No description provided for @sentinelsListDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays information about the Sentinels that are currently active in the network'**
  String get sentinelsListDescription;

  /// No description provided for @sentinelsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Sentinels List'**
  String get sentinelsListTitle;

  /// No description provided for @sessionTopic.
  ///
  /// In en, this message translates to:
  /// **'Session Topic'**
  String get sessionTopic;

  /// No description provided for @setBudgetForProject.
  ///
  /// In en, this message translates to:
  /// **'Set a budget for the project'**
  String get setBudgetForProject;

  /// No description provided for @shareQr.
  ///
  /// In en, this message translates to:
  /// **'Share QR'**
  String get shareQr;

  /// No description provided for @shareDepositIdWithCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Send your deposit ID to the counterparty via a messaging service so that they can join the swap.'**
  String get shareDepositIdWithCounterparty;

  /// No description provided for @showcaseProgressOfProject.
  ///
  /// In en, this message translates to:
  /// **'Showcase the progress of your project (e.g. Git PR/commit)'**
  String get showcaseProgressOfProject;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get showDetails;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @sortByLastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Sort by last update'**
  String get sortByLastUpdate;

  /// No description provided for @spawn.
  ///
  /// In en, this message translates to:
  /// **'Spawn'**
  String get spawn;

  /// No description provided for @stake.
  ///
  /// In en, this message translates to:
  /// **'Stake'**
  String get stake;

  /// No description provided for @stakeCollectDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays your current staking rewards that are ready to be collected. If there are any rewards available, you will be able to collect them'**
  String get stakeCollectDescription;

  /// No description provided for @stakeCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Stake Collect'**
  String get stakeCollectTitle;

  /// No description provided for @stakingDuration.
  ///
  /// In en, this message translates to:
  /// **'Staking duration'**
  String get stakingDuration;

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

  /// No description provided for @stakesListDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays information about the stake entries for the selected address'**
  String get stakesListDescription;

  /// No description provided for @stakesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Stakes'**
  String get stakesListTitle;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get starting;

  /// No description provided for @startingSwapPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Starting swap. This will take a moment.'**
  String get startingSwapPleaseWait;

  /// No description provided for @stakingRewardsDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays a chart with your staking rewards from your staking entries'**
  String get stakingRewardsDescription;

  /// No description provided for @stakingRewardsBlockCreated.
  ///
  /// In en, this message translates to:
  /// **'Successfully created block for collecting the staking rewards. It will take at least 30 seconds for the data to update and to be able to receive the rewards.'**
  String get stakingRewardsBlockCreated;

  /// No description provided for @stakingRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Staking Rewards'**
  String get stakingRewardsTitle;

  /// No description provided for @startProjectByCreatingPhase.
  ///
  /// In en, this message translates to:
  /// **'Start the project by creating a phase to unlock funds'**
  String get startProjectByCreatingPhase;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitDonation.
  ///
  /// In en, this message translates to:
  /// **'Submit donation'**
  String get submitDonation;

  /// No description provided for @submitPhase.
  ///
  /// In en, this message translates to:
  /// **'Submit phase'**
  String get submitPhase;

  /// No description provided for @submitProject.
  ///
  /// In en, this message translates to:
  /// **'Submit project'**
  String get submitProject;

  /// No description provided for @successfully.
  ///
  /// In en, this message translates to:
  /// **'successfully'**
  String get successfully;

  /// No description provided for @successfullyBurned.
  ///
  /// In en, this message translates to:
  /// **'Successfully burned {amount} {symbol}'**
  String successfullyBurned(Object amount, Object symbol);

  /// No description provided for @successfullyBurnedRequestedAmount.
  ///
  /// In en, this message translates to:
  /// **'You have successfully burned the requested amount: {amount} {symbol} {hash}'**
  String successfullyBurnedRequestedAmount(
    Object amount,
    Object hash,
    Object symbol,
  );

  /// No description provided for @successfullyMinted.
  ///
  /// In en, this message translates to:
  /// **'Successfully minted {amount} {symbol}'**
  String successfullyMinted(Object amount, Object symbol);

  /// No description provided for @successfullyMintedRequestedAmount.
  ///
  /// In en, this message translates to:
  /// **'You have successfully minted the requested amount: {amount} {symbol} {hash}'**
  String successfullyMintedRequestedAmount(
    Object amount,
    Object hash,
    Object symbol,
  );

  /// No description provided for @sufficientPlasma.
  ///
  /// In en, this message translates to:
  /// **'Sufficient Plasma'**
  String get sufficientPlasma;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @swapCompleted.
  ///
  /// In en, this message translates to:
  /// **'Swap completed.'**
  String get swapCompleted;

  /// No description provided for @swapCompletedFundsSoon.
  ///
  /// In en, this message translates to:
  /// **'Swap completed. You will receive the funds shortly.'**
  String get swapCompletedFundsSoon;

  /// No description provided for @swapJoined.
  ///
  /// In en, this message translates to:
  /// **'Swap joined.'**
  String get swapJoined;

  /// Shows the remaining time before a swap expires.
  ///
  /// In en, this message translates to:
  /// **'The swap will expire in {duration}'**
  String swapExpiresIn(String duration);

  /// No description provided for @swapHistoryFull.
  ///
  /// In en, this message translates to:
  /// **'Swap history is full'**
  String get swapHistoryFull;

  /// No description provided for @swapReclaimBlockCreated.
  ///
  /// In en, this message translates to:
  /// **'Successfully created block for reclaiming swap funds.'**
  String get swapReclaimBlockCreated;

  /// No description provided for @swapSecret.
  ///
  /// In en, this message translates to:
  /// **'Swap secret'**
  String get swapSecret;

  /// No description provided for @swapStarted.
  ///
  /// In en, this message translates to:
  /// **'Swap started.'**
  String get swapStarted;

  /// No description provided for @swapUnsuccessful.
  ///
  /// In en, this message translates to:
  /// **'The swap was unsuccessful.'**
  String get swapUnsuccessful;

  /// No description provided for @swapUnsuccessfulWaitForExpiration.
  ///
  /// In en, this message translates to:
  /// **'The swap was unsuccessful.\nPlease wait for your deposit to expire to reclaim your funds.'**
  String get swapUnsuccessfulWaitForExpiration;

  /// No description provided for @swapping.
  ///
  /// In en, this message translates to:
  /// **'Swapping'**
  String get swapping;

  /// No description provided for @syriusCachePath.
  ///
  /// In en, this message translates to:
  /// **'Syrius cache path'**
  String get syriusCachePath;

  /// No description provided for @syriusGitBranchName.
  ///
  /// In en, this message translates to:
  /// **'Syrius git branch name'**
  String get syriusGitBranchName;

  /// No description provided for @syriusGitCommitDate.
  ///
  /// In en, this message translates to:
  /// **'Syrius git commit date'**
  String get syriusGitCommitDate;

  /// No description provided for @syriusGitCommitHash.
  ///
  /// In en, this message translates to:
  /// **'Syrius git commit hash'**
  String get syriusGitCommitHash;

  /// No description provided for @syriusGitCommitMessage.
  ///
  /// In en, this message translates to:
  /// **'Syrius git commit message'**
  String get syriusGitCommitMessage;

  /// No description provided for @syriusGitOriginUrl.
  ///
  /// In en, this message translates to:
  /// **'Syrius git origin url'**
  String get syriusGitOriginUrl;

  /// No description provided for @syriusWalletPath.
  ///
  /// In en, this message translates to:
  /// **'Syrius wallet path'**
  String get syriusWalletPath;

  /// No description provided for @syriusWalletType.
  ///
  /// In en, this message translates to:
  /// **'Syrius wallet type'**
  String get syriusWalletType;

  /// No description provided for @syriusWalletVersion.
  ///
  /// In en, this message translates to:
  /// **'Syrius wallet version'**
  String get syriusWalletVersion;

  /// No description provided for @thankYouForSupportingAccelerator.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting the Accelerator'**
  String get thankYouForSupportingAccelerator;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @tokenAddedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'{name} token has been added to favorites'**
  String tokenAddedToFavorites(Object name);

  /// No description provided for @tokenBalanceDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays information about ZTS tokens that you currently hold in your wallet'**
  String get tokenBalanceDescription;

  /// No description provided for @tokenBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Token Balance'**
  String get tokenBalanceTitle;

  /// No description provided for @tokenBurnTooltip.
  ///
  /// In en, this message translates to:
  /// **'When enabled, any holder can burn tokens from their own balance. When disabled, only the token owner can burn.'**
  String get tokenBurnTooltip;

  /// No description provided for @tokenCreation.
  ///
  /// In en, this message translates to:
  /// **'ZNN Check'**
  String get tokenCreation;

  /// No description provided for @tokenDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tokenDetails;

  /// No description provided for @tokenDomain.
  ///
  /// In en, this message translates to:
  /// **'Token Domain'**
  String get tokenDomain;

  /// No description provided for @tokenDomainCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Token domain cannot be empty'**
  String get tokenDomainCannotBeEmpty;

  /// Validation error shown when a token domain exceeds the protocol maximum length.
  ///
  /// In en, this message translates to:
  /// **'Token domain must be at most {maxLength} characters'**
  String tokenDomainMaxLength(int maxLength);

  /// No description provided for @tokenIssuanceAddressDescription.
  ///
  /// In en, this message translates to:
  /// **'This will be your issuance address'**
  String get tokenIssuanceAddressDescription;

  /// No description provided for @tokenMetrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get tokenMetrics;

  /// No description provided for @tokenMintableBurnableOptions.
  ///
  /// In en, this message translates to:
  /// **'Mintable and Burnable Options'**
  String get tokenMintableBurnableOptions;

  /// No description provided for @tokenMintableBurnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mintable: {mintable}\nBurnable: {burnable}'**
  String tokenMintableBurnableSubtitle(Object burnable, Object mintable);

  /// No description provided for @tokenMintableTooltip.
  ///
  /// In en, this message translates to:
  /// **'Whether or not this token is mintable after creation'**
  String get tokenMintableTooltip;

  /// No description provided for @tokenName.
  ///
  /// In en, this message translates to:
  /// **'Token Name'**
  String get tokenName;

  /// No description provided for @tokenNameAllowedCharacters.
  ///
  /// In en, this message translates to:
  /// **'Token name must use letters and numbers, with optional single \'-\', \'.\', or \'_\' separators between them'**
  String get tokenNameAllowedCharacters;

  /// No description provided for @tokenNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Token name cannot be empty'**
  String get tokenNameCannotBeEmpty;

  /// Validation error shown when a token name exceeds the protocol maximum length.
  ///
  /// In en, this message translates to:
  /// **'Token name must be at most {maxLength} characters'**
  String tokenNameMaxLength(int maxLength);

  /// No description provided for @tokenInFavorites.
  ///
  /// In en, this message translates to:
  /// **'This token is in your favorites.'**
  String get tokenInFavorites;

  /// No description provided for @tokenNotInFavorites.
  ///
  /// In en, this message translates to:
  /// **'This token is not in your favorites.'**
  String get tokenNotInFavorites;

  /// No description provided for @tokenRemovedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'{name} token has been removed from favorites'**
  String tokenRemovedFromFavorites(Object name);

  /// No description provided for @tokenStandard.
  ///
  /// In en, this message translates to:
  /// **'Token standard'**
  String get tokenStandard;

  /// No description provided for @tokenStatusUtilityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Token status: utility or non-utility (e.g. security token)'**
  String get tokenStatusUtilityTooltip;

  /// No description provided for @tokenSummary.
  ///
  /// In en, this message translates to:
  /// **'Token {name} with symbol {symbol} and ZTS {tokenStandard}'**
  String tokenSummary(Object name, Object symbol, Object tokenStandard);

  /// No description provided for @tokenSupplyOutOfMax.
  ///
  /// In en, this message translates to:
  /// **'{totalSupply} out of {maxSupply} {symbol}'**
  String tokenSupplyOutOfMax(
    Object maxSupply,
    Object symbol,
    Object totalSupply,
  );

  /// No description provided for @tokenSymbol.
  ///
  /// In en, this message translates to:
  /// **'Token Symbol'**
  String get tokenSymbol;

  /// Validation error shown when a token symbol matches a reserved protocol symbol.
  ///
  /// In en, this message translates to:
  /// **'Token symbol cannot be {symbols}'**
  String tokenSymbolCannotBe(String symbols);

  /// No description provided for @tokenSymbolCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Token symbol cannot be empty'**
  String get tokenSymbolCannotBeEmpty;

  /// Validation error shown when a token symbol exceeds the protocol maximum length.
  ///
  /// In en, this message translates to:
  /// **'Token symbol must be at most {maxLength} characters'**
  String tokenSymbolMaxLength(int maxLength);

  /// No description provided for @tokenSymbolUppercaseAlphanumericOnly.
  ///
  /// In en, this message translates to:
  /// **'Token symbol must contain only uppercase letters and numbers'**
  String get tokenSymbolUppercaseAlphanumericOnly;

  /// No description provided for @tokenTransactions.
  ///
  /// In en, this message translates to:
  /// **'Token Transactions'**
  String get tokenTransactions;

  /// No description provided for @tokenVerified.
  ///
  /// In en, this message translates to:
  /// **'This token is verified.'**
  String get tokenVerified;

  /// No description provided for @tokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get tokens;

  /// No description provided for @tokensCardDescription.
  ///
  /// In en, this message translates to:
  /// **'This card displays a grid with all the ZTS tokens from the network, including ZTS tokens issued by you'**
  String get tokensCardDescription;

  /// No description provided for @topic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalDonationBudget.
  ///
  /// In en, this message translates to:
  /// **'Total donation budget'**
  String get totalDonationBudget;

  /// No description provided for @totalPhaseBudget.
  ///
  /// In en, this message translates to:
  /// **'Total phase budget'**
  String get totalPhaseBudget;

  /// No description provided for @totalProjectBudget.
  ///
  /// In en, this message translates to:
  /// **'Total project budget'**
  String get totalProjectBudget;

  /// No description provided for @totalSupply.
  ///
  /// In en, this message translates to:
  /// **'Total supply'**
  String get totalSupply;

  /// No description provided for @totalVotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} votes in total'**
  String totalVotesCount(int count);

  /// No description provided for @transactionError.
  ///
  /// In en, this message translates to:
  /// **'Error while receiving transaction'**
  String get transactionError;

  /// No description provided for @updatePhase.
  ///
  /// In en, this message translates to:
  /// **'Update phase'**
  String get updatePhase;

  /// No description provided for @updatingPhaseResetsVotes.
  ///
  /// In en, this message translates to:
  /// **'Updating this phase will reset all current votes'**
  String get updatingPhaseResetsVotes;

  /// No description provided for @valueMustBeZero.
  ///
  /// In en, this message translates to:
  /// **'Value must be 0'**
  String get valueMustBeZero;

  /// No description provided for @viewPhases.
  ///
  /// In en, this message translates to:
  /// **'View phases'**
  String get viewPhases;

  /// No description provided for @viewProjects.
  ///
  /// In en, this message translates to:
  /// **'View projects'**
  String get viewProjects;

  /// No description provided for @visitDomain.
  ///
  /// In en, this message translates to:
  /// **'Visit {domain}'**
  String visitDomain(Object domain);

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

  /// No description provided for @transferredTokenOwnership.
  ///
  /// In en, this message translates to:
  /// **'Successfully transferred ownership of {name} token'**
  String transferredTokenOwnership(Object name);

  /// No description provided for @transferredTokenOwnershipToAddress.
  ///
  /// In en, this message translates to:
  /// **'Successfully transferred ownership of {name} token to address {address}'**
  String transferredTokenOwnershipToAddress(Object address, Object name);

  /// No description provided for @transferTokenOwnership.
  ///
  /// In en, this message translates to:
  /// **'Transfer token ownership'**
  String get transferTokenOwnership;

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

  /// No description provided for @unsuccessful.
  ///
  /// In en, this message translates to:
  /// **'Unsuccessful'**
  String get unsuccessful;

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

  /// No description provided for @uriInvalid.
  ///
  /// In en, this message translates to:
  /// **'URI invalid'**
  String get uriInvalid;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @utilityToken.
  ///
  /// In en, this message translates to:
  /// **'Utility token'**
  String get utilityToken;

  /// No description provided for @usDateFormat.
  ///
  /// In en, this message translates to:
  /// **'MM/dd/yyyy'**
  String get usDateFormat;

  /// No description provided for @userCanceledQrScanning.
  ///
  /// In en, this message translates to:
  /// **'User canceled the QR scanning operation'**
  String get userCanceledQrScanning;

  /// No description provided for @userQrScanCanceled.
  ///
  /// In en, this message translates to:
  /// **'User QR scan canceled'**
  String get userQrScanCanceled;

  /// Warns the user to verify a token that is not in their favorites.
  ///
  /// In en, this message translates to:
  /// **'You are receiving a token that is not in your favorites. Please verify that the token standard is correct: {tokenStandard}'**
  String verifyNonFavoriteToken(String tokenStandard);

  /// No description provided for @viewSwapTutorial.
  ///
  /// In en, this message translates to:
  /// **'View swap tutorial'**
  String get viewSwapTutorial;

  /// No description provided for @viewPillars.
  ///
  /// In en, this message translates to:
  /// **'View Pillars'**
  String get viewPillars;

  /// No description provided for @viewMyTokens.
  ///
  /// In en, this message translates to:
  /// **'View my Tokens'**
  String get viewMyTokens;

  /// No description provided for @viewSentinels.
  ///
  /// In en, this message translates to:
  /// **'View Sentinels'**
  String get viewSentinels;

  /// No description provided for @votingClosed.
  ///
  /// In en, this message translates to:
  /// **'Voting closed'**
  String get votingClosed;

  /// No description provided for @votingClosesIn.
  ///
  /// In en, this message translates to:
  /// **'Voting closes in {duration}'**
  String votingClosesIn(String duration);

  /// No description provided for @votingOpen.
  ///
  /// In en, this message translates to:
  /// **'Voting open'**
  String get votingOpen;

  /// No description provided for @votingResults.
  ///
  /// In en, this message translates to:
  /// **'Voting results'**
  String get votingResults;

  /// No description provided for @waitingForDataFetching.
  ///
  /// In en, this message translates to:
  /// **'Waiting for data fetching'**
  String get waitingForDataFetching;

  /// No description provided for @waitingForCounterpartyToJoin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the counterparty to join the swap.'**
  String get waitingForCounterpartyToJoin;

  /// No description provided for @waitingForCounterpartyKeepRunning.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the counterparty. Please keep Syrius running.'**
  String get waitingForCounterpartyKeepRunning;

  /// Explains when an incorrect swap deposit can be reclaimed.
  ///
  /// In en, this message translates to:
  /// **'If the token or the amount you are receiving is not what you have agreed upon, wait until your deposit expires to reclaim your funds.\nYour deposit will expire at {expirationDate}.'**
  String waitToReclaimIncorrectDeposit(String expirationDate);

  /// No description provided for @walletConnectLink.
  ///
  /// In en, this message translates to:
  /// **'WalletConnect Link'**
  String get walletConnectLink;

  /// No description provided for @walletConnectPairingDescription.
  ///
  /// In en, this message translates to:
  /// **'A pairing refers to the initial process of establishing a secure connection between a wallet and the dApp. Once the pairing is complete, a session is established, which allows the dApp to communicate with the wallet securely over the Internet'**
  String get walletConnectPairingDescription;

  /// No description provided for @walletConnectPairingList.
  ///
  /// In en, this message translates to:
  /// **'WalletConnect Pairing List'**
  String get walletConnectPairingList;

  /// No description provided for @walletConnectSessionDescription.
  ///
  /// In en, this message translates to:
  /// **'A session refers to a live connection between a user\'s wallet and a dApp. A session allows the dApp to communicate with the wallet securely over the Internet'**
  String get walletConnectSessionDescription;

  /// No description provided for @walletConnectSessionsList.
  ///
  /// In en, this message translates to:
  /// **'WalletConnect Sessions List'**
  String get walletConnectSessionsList;

  /// No description provided for @walletConnectUri.
  ///
  /// In en, this message translates to:
  /// **'WalletConnect URI'**
  String get walletConnectUri;

  /// No description provided for @websites.
  ///
  /// In en, this message translates to:
  /// **'Websites'**
  String get websites;

  /// No description provided for @walletNotAutoLocked.
  ///
  /// In en, this message translates to:
  /// **'Your wallet will not be auto-locked while the swap is in progress.'**
  String get walletNotAutoLocked;

  /// No description provided for @walletResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Wallet reset failed'**
  String get walletResetFailed;

  /// No description provided for @cacheDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Cache deletion failed'**
  String get cacheDeletionFailed;

  /// Error dialog body shown when clearing local wallet or cache data fails and offers a retry.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear local wallet data:\n{error}\n\nWould you like to retry?'**
  String failedToClearLocalWalletData(String error);

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

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get yes;

  /// No description provided for @yesVotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Yes votes'**
  String yesVotesCount(int count);

  /// No description provided for @youHaveDeposited.
  ///
  /// In en, this message translates to:
  /// **'You have deposited {coins} {kQsrCoinSymbol}'**
  String youHaveDeposited(Object coins, Object kQsrCoinSymbol);

  /// No description provided for @youAreReceiving.
  ///
  /// In en, this message translates to:
  /// **'You are receiving'**
  String get youAreReceiving;

  /// No description provided for @youAreSending.
  ///
  /// In en, this message translates to:
  /// **'You are sending'**
  String get youAreSending;

  /// No description provided for @yourAddress.
  ///
  /// In en, this message translates to:
  /// **'Your address'**
  String get yourAddress;

  /// No description provided for @yourDepositId.
  ///
  /// In en, this message translates to:
  /// **'Your deposit ID'**
  String get yourDepositId;

  /// No description provided for @yourDonationMatters.
  ///
  /// In en, this message translates to:
  /// **'Your donation matters'**
  String get yourDonationMatters;

  /// No description provided for @yourProjectOwnerAddress.
  ///
  /// In en, this message translates to:
  /// **'This will be your project owner address'**
  String get yourProjectOwnerAddress;

  /// No description provided for @zenonBitcoinTalk.
  ///
  /// In en, this message translates to:
  /// **'Zenon Bitcoin Talk'**
  String get zenonBitcoinTalk;

  /// No description provided for @zenonDiscord.
  ///
  /// In en, this message translates to:
  /// **'Zenon Discord'**
  String get zenonDiscord;

  /// No description provided for @zenonExplorer.
  ///
  /// In en, this message translates to:
  /// **'Zenon Explorer'**
  String get zenonExplorer;

  /// No description provided for @zenonGithub.
  ///
  /// In en, this message translates to:
  /// **'Zenon Github'**
  String get zenonGithub;

  /// No description provided for @zenonHub.
  ///
  /// In en, this message translates to:
  /// **'Zenon Hub'**
  String get zenonHub;

  /// No description provided for @zenonHubExplorer.
  ///
  /// In en, this message translates to:
  /// **'Zenon Hub Explorer'**
  String get zenonHubExplorer;

  /// No description provided for @zenonMainDataPath.
  ///
  /// In en, this message translates to:
  /// **'Zenon main data path'**
  String get zenonMainDataPath;

  /// No description provided for @zenonMedium.
  ///
  /// In en, this message translates to:
  /// **'Zenon Medium'**
  String get zenonMedium;

  /// No description provided for @zenonNetwork.
  ///
  /// In en, this message translates to:
  /// **'Zenon Network'**
  String get zenonNetwork;

  /// No description provided for @zenonNodeBuildVersion.
  ///
  /// In en, this message translates to:
  /// **'Zenon Node build version'**
  String get zenonNodeBuildVersion;

  /// No description provided for @zenonNodeChainIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Zenon Node chain identifier'**
  String get zenonNodeChainIdentifier;

  /// No description provided for @zenonNodeGitCommitHash.
  ///
  /// In en, this message translates to:
  /// **'Zenon Node git commit hash'**
  String get zenonNodeGitCommitHash;

  /// No description provided for @zenonNodeKernelVersion.
  ///
  /// In en, this message translates to:
  /// **'Zenon Node kernel version'**
  String get zenonNodeKernelVersion;

  /// No description provided for @zenonNodeNumberOfProcessors.
  ///
  /// In en, this message translates to:
  /// **'Zenon Node number of processors'**
  String get zenonNodeNumberOfProcessors;

  /// No description provided for @zenonNodeOperatingSystem.
  ///
  /// In en, this message translates to:
  /// **'Zenon Node operating system'**
  String get zenonNodeOperatingSystem;

  /// No description provided for @zenonNodePlatform.
  ///
  /// In en, this message translates to:
  /// **'Zenon Node platform'**
  String get zenonNodePlatform;

  /// No description provided for @zenonNodePlatformVersion.
  ///
  /// In en, this message translates to:
  /// **'Zenon Node platform version'**
  String get zenonNodePlatformVersion;

  /// No description provided for @zenonOrgCommunity.
  ///
  /// In en, this message translates to:
  /// **'Zenon ORG Community'**
  String get zenonOrgCommunity;

  /// No description provided for @zenonOrgCommunityForum.
  ///
  /// In en, this message translates to:
  /// **'Zenon ORG Community Forum'**
  String get zenonOrgCommunityForum;

  /// No description provided for @zenonOrgCommunityWiki.
  ///
  /// In en, this message translates to:
  /// **'ZenonORG Community Wiki'**
  String get zenonOrgCommunityWiki;

  /// No description provided for @zenonReddit.
  ///
  /// In en, this message translates to:
  /// **'Zenon Reddit'**
  String get zenonReddit;

  /// No description provided for @zenonSdkVersion.
  ///
  /// In en, this message translates to:
  /// **'Zenon SDK version'**
  String get zenonSdkVersion;

  /// No description provided for @zenonTelegram.
  ///
  /// In en, this message translates to:
  /// **'Zenon Telegram'**
  String get zenonTelegram;

  /// No description provided for @zenonTools.
  ///
  /// In en, this message translates to:
  /// **'Zenon Tools'**
  String get zenonTools;

  /// No description provided for @zenonTransactions.
  ///
  /// In en, this message translates to:
  /// **'{zenon} transactions'**
  String zenonTransactions(Object zenon);

  /// No description provided for @zenonTwitter.
  ///
  /// In en, this message translates to:
  /// **'Zenon Twitter'**
  String get zenonTwitter;

  /// No description provided for @zenonWhitepaper.
  ///
  /// In en, this message translates to:
  /// **'Zenon Whitepaper'**
  String get zenonWhitepaper;

  /// No description provided for @zenonWiki.
  ///
  /// In en, this message translates to:
  /// **'Zenon Wiki'**
  String get zenonWiki;

  /// No description provided for @zenonYoutube.
  ///
  /// In en, this message translates to:
  /// **'Zenon Youtube'**
  String get zenonYoutube;

  /// No description provided for @znnAmount.
  ///
  /// In en, this message translates to:
  /// **'ZNN Amount'**
  String get znnAmount;

  /// No description provided for @znnController.
  ///
  /// In en, this message translates to:
  /// **'znn-controller '**
  String get znnController;

  /// No description provided for @znnDonationSubmittedQsrFailed.
  ///
  /// In en, this message translates to:
  /// **'ZNN donation was submitted, but the QSR donation failed. Retry to submit only the remaining QSR donation.'**
  String get znnDonationSubmittedQsrFailed;

  /// No description provided for @ztsSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Coins and tokens can be searched by name - \"Zenon\" -, by symbol - \"ZNN\" -, and by token standard - \"zts1znnxxxxxxxxxxxxx9z4ulx\"'**
  String get ztsSearchDescription;

  /// No description provided for @accountChainHeight.
  ///
  /// In en, this message translates to:
  /// **'Account-chain height'**
  String get accountChainHeight;

  /// No description provided for @accountChainStats.
  ///
  /// In en, this message translates to:
  /// **'Account-chain Stats'**
  String get accountChainStats;

  /// Action label for adding one or more wallet addresses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 address} other{Add {count} addresses}}'**
  String addAddressesCount(int count);

  /// No description provided for @addNode.
  ///
  /// In en, this message translates to:
  /// **'Add node'**
  String get addNode;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @allWalletDataErasedPermanently.
  ///
  /// In en, this message translates to:
  /// **'All your wallet data will be erased permanently. Make sure you have a backup of your mnemonic or Seed Vault & Seed Vault Key before you proceed with erasing the wallet'**
  String get allWalletDataErasedPermanently;

  /// No description provided for @alphanetChainIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Alphanet chain identifier'**
  String get alphanetChainIdentifier;

  /// No description provided for @autoEraseLimitChanged.
  ///
  /// In en, this message translates to:
  /// **'Auto-erase attempts limit successfully changed'**
  String get autoEraseLimitChanged;

  /// No description provided for @autoEraseLimitNowAttempts.
  ///
  /// In en, this message translates to:
  /// **'The auto-erase limit has now {attempts} attempt(s)'**
  String autoEraseLimitNowAttempts(String attempts);

  /// No description provided for @autoEraseWallet.
  ///
  /// In en, this message translates to:
  /// **'Auto-erase wallet'**
  String get autoEraseWallet;

  /// No description provided for @autoLockWallet.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock wallet'**
  String get autoLockWallet;

  /// No description provided for @autoReceiver.
  ///
  /// In en, this message translates to:
  /// **'Auto-receiver'**
  String get autoReceiver;

  /// No description provided for @autoReceiverPreferenceStatus.
  ///
  /// In en, this message translates to:
  /// **'Auto-receiver preference was {status}'**
  String autoReceiverPreferenceStatus(String status);

  /// No description provided for @autoReceiverStatus.
  ///
  /// In en, this message translates to:
  /// **'Auto-receiver {status}'**
  String autoReceiverStatus(String status);

  /// No description provided for @automaticallyReceiveTransactions.
  ///
  /// In en, this message translates to:
  /// **'Automatically receive transactions'**
  String get automaticallyReceiveTransactions;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @backupSeedEncryptedOrClearText.
  ///
  /// In en, this message translates to:
  /// **'Backup your seed using the syrius standard format JSON (encrypted, recommended) or show it on the screen (clear text, not recommended)'**
  String get backupSeedEncryptedOrClearText;

  /// No description provided for @backupWallet.
  ///
  /// In en, this message translates to:
  /// **'Backup wallet'**
  String get backupWallet;

  /// No description provided for @blockHash.
  ///
  /// In en, this message translates to:
  /// **'Block hash'**
  String get blockHash;

  /// No description provided for @chainIdentifierMismatch.
  ///
  /// In en, this message translates to:
  /// **'Chain identifier mismatch'**
  String get chainIdentifierMismatch;

  /// No description provided for @chainIdentifierMismatchDetails.
  ///
  /// In en, this message translates to:
  /// **'Chain identifier mismatch\nClient chain identifier: {clientChainId}\nNode chain identifier: {nodeChainId}'**
  String chainIdentifierMismatchDetails(int clientChainId, int nodeChainId);

  /// No description provided for @chainIdentifierPreventsReplayAttacks.
  ///
  /// In en, this message translates to:
  /// **'The chain identifier is used in transaction signing to prevent replay attacks'**
  String get chainIdentifierPreventsReplayAttacks;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changeWalletPassword.
  ///
  /// In en, this message translates to:
  /// **'Change wallet password'**
  String get changeWalletPassword;

  /// No description provided for @changeWalletSecurityParameters.
  ///
  /// In en, this message translates to:
  /// **'Change the security parameters of the wallet'**
  String get changeWalletSecurityParameters;

  /// No description provided for @changedClientChainIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Successfully changed client chain identifier to {chainId}'**
  String changedClientChainIdentifier(int chainId);

  /// No description provided for @changedClientChainIdentifierFromTo.
  ///
  /// In en, this message translates to:
  /// **'Successfully changed client chain identifier from {oldChainId} to {newChainId}'**
  String changedClientChainIdentifierFromTo(int oldChainId, int newChainId);

  /// No description provided for @clientAndNodeChainIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Client chain identifier: {clientChainId}\nNode chain identifier: {nodeChainId}'**
  String clientAndNodeChainIdentifiers(int clientChainId, int nodeChainId);

  /// No description provided for @clientChainIdentifierSelection.
  ///
  /// In en, this message translates to:
  /// **'Client chain identifier selection'**
  String get clientChainIdentifierSelection;

  /// No description provided for @clipboardWatcherPreferenceStatus.
  ///
  /// In en, this message translates to:
  /// **'Clipboard watcher preference was {status}'**
  String clipboardWatcherPreferenceStatus(String status);

  /// No description provided for @clipboardWatcherStatus.
  ///
  /// In en, this message translates to:
  /// **'Clipboard watcher {status}'**
  String clipboardWatcherStatus(String status);

  /// No description provided for @communityNode.
  ///
  /// In en, this message translates to:
  /// **'Community Node'**
  String get communityNode;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmNode.
  ///
  /// In en, this message translates to:
  /// **'Confirm node'**
  String get confirmNode;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmScale.
  ///
  /// In en, this message translates to:
  /// **'Confirm scale'**
  String get confirmScale;

  /// No description provided for @confirmTheme.
  ///
  /// In en, this message translates to:
  /// **'Confirm theme'**
  String get confirmTheme;

  /// No description provided for @connectionCouldNotBeEstablished.
  ///
  /// In en, this message translates to:
  /// **'Connection could not be established to {node}'**
  String connectionCouldNotBeEstablished(String node);

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @couldNotReconnectToNode.
  ///
  /// In en, this message translates to:
  /// **'Could not reconnect to {node}'**
  String couldNotReconnectToNode(String node);

  /// No description provided for @currentClientChainIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Current client chain identifier is {chainId}'**
  String currentClientChainIdentifier(int chainId);

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @addressNumber.
  ///
  /// In en, this message translates to:
  /// **'Address {index}'**
  String addressNumber(int index);

  /// No description provided for @deleteCache.
  ///
  /// In en, this message translates to:
  /// **'Delete cache'**
  String get deleteCache;

  /// No description provided for @deleteNode.
  ///
  /// In en, this message translates to:
  /// **'Delete node'**
  String get deleteNode;

  /// No description provided for @deleteNodeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {node} from the list of nodes? This action can\'t be undone.'**
  String deleteNodeConfirmation(String node);

  /// No description provided for @deleteWalletCacheAndCloseApp.
  ///
  /// In en, this message translates to:
  /// **'This option will delete the wallet cache and close the application'**
  String get deleteWalletCacheAndCloseApp;

  /// No description provided for @desktopNotificationsPreferenceStatus.
  ///
  /// In en, this message translates to:
  /// **'Desktop notifications preference was {status}'**
  String desktopNotificationsPreferenceStatus(String status);

  /// No description provided for @desktopNotificationsStatus.
  ///
  /// In en, this message translates to:
  /// **'Desktop notifications {status}'**
  String desktopNotificationsStatus(String status);

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get disabled;

  /// No description provided for @disconnectedFromNode.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from node'**
  String get disconnectedFromNode;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @displaysAccountChainInformation.
  ///
  /// In en, this message translates to:
  /// **'This card displays information regarding the account-chain for the specified address'**
  String get displaysAccountChainInformation;

  /// No description provided for @displaysConnectedNetworkPeers.
  ///
  /// In en, this message translates to:
  /// **'This card displays information about connected network peers'**
  String get displaysConnectedNetworkPeers;

  /// No description provided for @dumpMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Dump Mnemonic'**
  String get dumpMnemonic;

  /// No description provided for @editNode.
  ///
  /// In en, this message translates to:
  /// **'Edit node'**
  String get editNode;

  /// No description provided for @embeddedNodeSyncExplanation.
  ///
  /// In en, this message translates to:
  /// **'By default Syrius connects to its own built-in full node, which is called the Embedded Node. It may take up to 24 hours to fully sync the network via the embedded node. During this time, you cannot send or receive transactions.\n\nIf you want to get started right away, please connect to a community node.'**
  String get embeddedNodeSyncExplanation;

  /// No description provided for @embeddedNodeValidatesTransactions.
  ///
  /// In en, this message translates to:
  /// **'The Embedded Node validates all network transactions\nIt may take several hours to fully sync with the network'**
  String get embeddedNodeValidatesTransactions;

  /// No description provided for @emptyAccountChain.
  ///
  /// In en, this message translates to:
  /// **'Empty account-chain'**
  String get emptyAccountChain;

  /// No description provided for @enableClipboardWatcher.
  ///
  /// In en, this message translates to:
  /// **'Enable clipboard watcher'**
  String get enableClipboardWatcher;

  /// No description provided for @enableDesktopNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable desktop notifications'**
  String get enableDesktopNotifications;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get enabled;

  /// No description provided for @encryptedConnection.
  ///
  /// In en, this message translates to:
  /// **'Encrypted connection'**
  String get encryptedConnection;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter message'**
  String get enterMessage;

  /// No description provided for @enterPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Enter public key'**
  String get enterPublicKey;

  /// No description provided for @enterSignature.
  ///
  /// In en, this message translates to:
  /// **'Enter signature'**
  String get enterSignature;

  /// No description provided for @enterSignedHash.
  ///
  /// In en, this message translates to:
  /// **'Enter signed hash'**
  String get enterSignedHash;

  /// No description provided for @enterStrongSeedVaultKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter a strong Seed Vault Key to encrypt your Seed'**
  String get enterStrongSeedVaultKey;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get enterText;

  /// No description provided for @enterWalletPasswordToDumpMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Enter the wallet password to dump the mnemonic'**
  String get enterWalletPasswordToDumpMnemonic;

  /// No description provided for @eraseAfterFailedPasswordAttempts.
  ///
  /// In en, this message translates to:
  /// **'Erase after {attempts} failed password attempts'**
  String eraseAfterFailedPasswordAttempts(int attempts);

  /// No description provided for @eraseWalletFilesMakeSureBackup.
  ///
  /// In en, this message translates to:
  /// **'This option will erase the wallet files. Make sure you have a backup first'**
  String get eraseWalletFilesMakeSureBackup;

  /// No description provided for @errorAccessingWalletForBackup.
  ///
  /// In en, this message translates to:
  /// **'Error while accessing wallet for backup'**
  String get errorAccessingWalletForBackup;

  /// No description provided for @errorAddingNewNode.
  ///
  /// In en, this message translates to:
  /// **'Error while adding new node'**
  String get errorAddingNewNode;

  /// No description provided for @errorChangingAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while changing the address label'**
  String get errorChangingAddressLabel;

  /// No description provided for @errorChangingClipboardWatcher.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while changing clipboard watcher preference'**
  String get errorChangingClipboardWatcher;

  /// No description provided for @errorChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while trying to change password'**
  String get errorChangingPassword;

  /// No description provided for @errorConfirmingAutoEraseLimit.
  ///
  /// In en, this message translates to:
  /// **'Error while confirming auto-erase limit'**
  String get errorConfirmingAutoEraseLimit;

  /// No description provided for @errorConfirmingAutoLockInterval.
  ///
  /// In en, this message translates to:
  /// **'Error while confirming auto-lock interval'**
  String get errorConfirmingAutoLockInterval;

  /// No description provided for @errorDecryptingWallet.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while trying to decrypt wallet'**
  String get errorDecryptingWallet;

  /// No description provided for @errorDeletingNodeFromDatabase.
  ///
  /// In en, this message translates to:
  /// **'Error during deleting node {node} from the database'**
  String errorDeletingNodeFromDatabase(String node);

  /// No description provided for @errorExportingSeedVault.
  ///
  /// In en, this message translates to:
  /// **'Error while exporting Seed Vault'**
  String get errorExportingSeedVault;

  /// No description provided for @errorSettingAutoReceivePreference.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while setting automatic receive preference'**
  String get errorSettingAutoReceivePreference;

  /// No description provided for @errorSettingClientChainIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Error while setting the new client chain identifier'**
  String get errorSettingClientChainIdentifier;

  /// No description provided for @errorSettingDesktopNotifications.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while setting desktop notifications preference'**
  String get errorSettingDesktopNotifications;

  /// No description provided for @errorSettingLaunchAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while setting launch at startup preference'**
  String get errorSettingLaunchAtStartup;

  /// No description provided for @errorSigningMessage.
  ///
  /// In en, this message translates to:
  /// **'Error while signing message'**
  String get errorSigningMessage;

  /// No description provided for @errorVerifyingFileHash.
  ///
  /// In en, this message translates to:
  /// **'Error while verifying file hash'**
  String get errorVerifyingFileHash;

  /// No description provided for @errorVerifyingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error while verifying message'**
  String get errorVerifyingMessage;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportSeedVault.
  ///
  /// In en, this message translates to:
  /// **'Export Seed Vault'**
  String get exportSeedVault;

  /// No description provided for @fileHashVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'File hash verified successfully'**
  String get fileHashVerifiedSuccessfully;

  /// No description provided for @fileHashVerifiedWithSignedHash.
  ///
  /// In en, this message translates to:
  /// **'File hash was successfully verified with the signed hash: {signedHash}'**
  String fileHashVerifiedWithSignedHash(String signedHash);

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @genericWalletAndNetworkInfo.
  ///
  /// In en, this message translates to:
  /// **'Generic wallet & network information'**
  String get genericWalletAndNetworkInfo;

  /// No description provided for @hashOrPublicKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Hash or public key invalid'**
  String get hashOrPublicKeyInvalid;

  /// No description provided for @huge.
  ///
  /// In en, this message translates to:
  /// **'Huge'**
  String get huge;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @integratedFullNodeEnhancedSecurity.
  ///
  /// In en, this message translates to:
  /// **'Integrated Full Node: enhanced security and privacy'**
  String get integratedFullNodeEnhancedSecurity;

  /// No description provided for @ip.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get ip;

  /// No description provided for @labelAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Label already exists'**
  String get labelAlreadyExists;

  /// No description provided for @labelAlreadyExistsInDatabase.
  ///
  /// In en, this message translates to:
  /// **'Label {label} already exists in the database'**
  String labelAlreadyExistsInDatabase(String label);

  /// No description provided for @labelCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Label can\'t be empty'**
  String get labelCannotBeEmpty;

  /// No description provided for @labelExceedsMaxLength.
  ///
  /// In en, this message translates to:
  /// **'The label {label} is {length} characters long, which is more than the {maxLength} limit.'**
  String labelExceedsMaxLength(String label, int length, int maxLength);

  /// No description provided for @labelHasTooManyCharacters.
  ///
  /// In en, this message translates to:
  /// **'The label has more than {maxLength} characters'**
  String labelHasTooManyCharacters(int maxLength);

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @launchAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Launch at startup'**
  String get launchAtStartup;

  /// No description provided for @launchAtStartupPreferenceStatus.
  ///
  /// In en, this message translates to:
  /// **'Launch at startup preference was {status}'**
  String launchAtStartupPreferenceStatus(String status);

  /// No description provided for @launchAtStartupStatus.
  ///
  /// In en, this message translates to:
  /// **'Launch startup {status}'**
  String launchAtStartupStatus(String status);

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @listensClipboardForWalletConnectUri.
  ///
  /// In en, this message translates to:
  /// **'Listens to the values passed to the clipboard and sends a notification when a WalletConnect URI has been copied'**
  String get listensClipboardForWalletConnectUri;

  /// No description provided for @locale.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get locale;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @lockAfterMinutesOfInactivity.
  ///
  /// In en, this message translates to:
  /// **'Lock after {minutes} minutes of inactivity'**
  String lockAfterMinutesOfInactivity(int minutes);

  /// No description provided for @messageOrSignatureInvalid.
  ///
  /// In en, this message translates to:
  /// **'Message or signature invalid'**
  String get messageOrSignatureInvalid;

  /// No description provided for @messageVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Message verified successfully'**
  String get messageVerifiedSuccessfully;

  /// No description provided for @messageVerifiedWithSignature.
  ///
  /// In en, this message translates to:
  /// **'The message: {message} was successfully verified with the signature: {signature}'**
  String messageVerifiedWithSignature(String message, String signature);

  /// No description provided for @momentumHash.
  ///
  /// In en, this message translates to:
  /// **'Momentum hash'**
  String get momentumHash;

  /// No description provided for @momentumHeight.
  ///
  /// In en, this message translates to:
  /// **'Momentum height'**
  String get momentumHeight;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @noPeersFound.
  ///
  /// In en, this message translates to:
  /// **'No peers found'**
  String get noPeersFound;

  /// No description provided for @nodeAddressCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Node address can\'t be empty'**
  String get nodeAddressCannotBeEmpty;

  /// No description provided for @nodeAddressWithPort.
  ///
  /// In en, this message translates to:
  /// **'Node address with port'**
  String get nodeAddressWithPort;

  /// No description provided for @nodeAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Node already exists'**
  String get nodeAlreadyExists;

  /// No description provided for @nodeAlreadyExistsNamed.
  ///
  /// In en, this message translates to:
  /// **'Node {node} already exists'**
  String nodeAlreadyExistsNamed(String node);

  /// No description provided for @nodeHasDifferentChainIdentifier.
  ///
  /// In en, this message translates to:
  /// **'The node {node} you are connecting to has a different chain identifier {nodeChainId} than the current client chain identifier {currentChainId}'**
  String nodeHasDifferentChainIdentifier(
    String node,
    int nodeChainId,
    int currentChainId,
  );

  /// No description provided for @nodeHasTooManyCharacters.
  ///
  /// In en, this message translates to:
  /// **'The node has more than {maxLength} characters'**
  String nodeHasTooManyCharacters(int maxLength);

  /// No description provided for @nodeManagement.
  ///
  /// In en, this message translates to:
  /// **'Node Management'**
  String get nodeManagement;

  /// No description provided for @nodeSelection.
  ///
  /// In en, this message translates to:
  /// **'Node selection'**
  String get nodeSelection;

  /// No description provided for @nonAlphanetChainIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Non-alphanet chain identifier'**
  String get nonAlphanetChainIdentifier;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @otherWalletOptions.
  ///
  /// In en, this message translates to:
  /// **'Other wallet options'**
  String get otherWalletOptions;

  /// No description provided for @useStrongPasswordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Use a password that has at least 8 characters, one number, one uppercase letter, one lowercase letter and one symbol'**
  String get useStrongPasswordRequirements;

  /// No description provided for @pasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get pasteFromClipboard;

  /// No description provided for @peers.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get peers;

  /// No description provided for @peersAvailable.
  ///
  /// In en, this message translates to:
  /// **'Peers available'**
  String get peersAvailable;

  /// No description provided for @peersConnected.
  ///
  /// In en, this message translates to:
  /// **'Peers connected'**
  String get peersConnected;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @proceedAnyway.
  ///
  /// In en, this message translates to:
  /// **'Proceed anyway'**
  String get proceedAnyway;

  /// No description provided for @publicKey.
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get publicKey;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @repeatNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat new password'**
  String get repeatNewPassword;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetWallet.
  ///
  /// In en, this message translates to:
  /// **'Reset wallet'**
  String get resetWallet;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get seed;

  /// No description provided for @seedVault.
  ///
  /// In en, this message translates to:
  /// **'Seed Vault'**
  String get seedVault;

  /// No description provided for @seedVaultBackupExplanation.
  ///
  /// In en, this message translates to:
  /// **'A Seed Vault is an encrypted file for backing up your Seed. The Seed is encrypted with a Seed Vault Key and cannot be accessed without it. Make sure you backup your Seed Vault in multiple offline locations (e.g. USB, external HDD) and do not lose your Seed Vault Key. If you lose the Seed Vault file or you don\'t remember the Seed Vault Key you lose access to your funds.'**
  String get seedVaultBackupExplanation;

  /// No description provided for @seedVaultExported.
  ///
  /// In en, this message translates to:
  /// **'Seed Vault successfully exported'**
  String get seedVaultExported;

  /// No description provided for @seedVaultExportedToPath.
  ///
  /// In en, this message translates to:
  /// **'The Seed Vault was successfully exported to {path}'**
  String seedVaultExportedToPath(String path);

  /// No description provided for @seedVaultKey.
  ///
  /// In en, this message translates to:
  /// **'Seed Vault Key'**
  String get seedVaultKey;

  /// No description provided for @selectDefaultAddressForOperations.
  ///
  /// In en, this message translates to:
  /// **'Select the default address that will be used throughout the wallet for any network operation'**
  String get selectDefaultAddressForOperations;

  /// No description provided for @setZnnNodeToConnect.
  ///
  /// In en, this message translates to:
  /// **'This card allows one to set the ZNN Node used to connect to. By default the wallet is connected to the Embedded Node. If you are running a local ZNN Node, please use the localhost option'**
  String get setZnnNodeToConnect;

  /// No description provided for @sign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get sign;

  /// No description provided for @signFile.
  ///
  /// In en, this message translates to:
  /// **'Sign file'**
  String get signFile;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @signedHash.
  ///
  /// In en, this message translates to:
  /// **'Signed hash'**
  String get signedHash;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @storeSeedVaultOfflineLocations.
  ///
  /// In en, this message translates to:
  /// **'Store your Seed Vault and Seed Vault Key in secure and separate offline locations. You will need both to access your funds'**
  String get storeSeedVaultOfflineLocations;

  /// No description provided for @successfullyAddedNode.
  ///
  /// In en, this message translates to:
  /// **'Successfully added node {node}'**
  String successfullyAddedNode(String node);

  /// No description provided for @successfullyConnectedToNode.
  ///
  /// In en, this message translates to:
  /// **'Successfully connected to {node}'**
  String successfullyConnectedToNode(String node);

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @textScaleChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Text scale change failed'**
  String get textScaleChangeFailed;

  /// No description provided for @textScaleChanged.
  ///
  /// In en, this message translates to:
  /// **'Text scale changed'**
  String get textScaleChanged;

  /// No description provided for @textScaleChangedDetails.
  ///
  /// In en, this message translates to:
  /// **'Text scale successfully changed to {scale}'**
  String textScaleChangedDetails(String scale);

  /// No description provided for @textScaling.
  ///
  /// In en, this message translates to:
  /// **'Text scaling'**
  String get textScaling;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeModeChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Theme mode change failed'**
  String get themeModeChangeFailed;

  /// No description provided for @themeModeChanged.
  ///
  /// In en, this message translates to:
  /// **'Theme mode changed'**
  String get themeModeChanged;

  /// No description provided for @themeModeChangedDetails.
  ///
  /// In en, this message translates to:
  /// **'Theme mode successfully changed to {mode}'**
  String themeModeChangedDetails(String mode);

  /// No description provided for @timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get timestamp;

  /// No description provided for @uncheckToDisableAutoReceiver.
  ///
  /// In en, this message translates to:
  /// **'Uncheck to disable the auto-receiver and receive transactions manually'**
  String get uncheckToDisableAutoReceiver;

  /// No description provided for @unencryptedConnection.
  ///
  /// In en, this message translates to:
  /// **'Unencrypted connection'**
  String get unencryptedConnection;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verifyFile.
  ///
  /// In en, this message translates to:
  /// **'Verify file'**
  String get verifyFile;

  /// No description provided for @walletAppearanceAndThemeSettings.
  ///
  /// In en, this message translates to:
  /// **'Wallet appearance and theme settings'**
  String get walletAppearanceAndThemeSettings;

  /// No description provided for @walletOptions.
  ///
  /// In en, this message translates to:
  /// **'Wallet Options'**
  String get walletOptions;

  /// No description provided for @willSecurelyStoreSeedVault.
  ///
  /// In en, this message translates to:
  /// **'I will securely store the Seed Vault & Seed Vault Key'**
  String get willSecurelyStoreSeedVault;

  /// No description provided for @accessWallet.
  ///
  /// In en, this message translates to:
  /// **'Access wallet'**
  String get accessWallet;

  /// Displays the number of unlock attempts remaining before wallet reset.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts left'**
  String attemptsLeft(int count);

  /// No description provided for @backedUpSeedInSafeLocation.
  ///
  /// In en, this message translates to:
  /// **'I have backed up my seed in a safe location'**
  String get backedUpSeedInSafeLocation;

  /// No description provided for @chooseYourDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose your device'**
  String get chooseYourDevice;

  /// Prompts the user to confirm the address for a hardware wallet account index.
  ///
  /// In en, this message translates to:
  /// **'Confirm address for account index: {index}'**
  String confirmAddressAccountIndex(int index);

  /// No description provided for @confirmYourSeed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your seed'**
  String get confirmYourSeed;

  /// No description provided for @connectAndUnlockYourDevice.
  ///
  /// In en, this message translates to:
  /// **'Please connect and unlock your device'**
  String get connectAndUnlockYourDevice;

  /// No description provided for @createWallet.
  ///
  /// In en, this message translates to:
  /// **'Create wallet'**
  String get createWallet;

  /// No description provided for @createWalletPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet password'**
  String get createWalletPassword;

  /// No description provided for @deviceNotConnectedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Not connected, please connect the device and try again.'**
  String get deviceNotConnectedTryAgain;

  /// No description provided for @dragAndDropWordsCorrectOrder.
  ///
  /// In en, this message translates to:
  /// **'Drag & drop the words in the correct order'**
  String get dragAndDropWordsCorrectOrder;

  /// No description provided for @dragAndDropWordsOnEmptyOrIncorrect.
  ///
  /// In en, this message translates to:
  /// **'You can drag & drop words on empty boxes or incorrect words'**
  String get dragAndDropWordsOnEmptyOrIncorrect;

  /// No description provided for @enterPasswordToAccessWallet.
  ///
  /// In en, this message translates to:
  /// **'Enter the password to access the wallet'**
  String get enterPasswordToAccessWallet;

  /// Displays a generic error prefix followed by the error message.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @exportSeed.
  ///
  /// In en, this message translates to:
  /// **'Export Seed'**
  String get exportSeed;

  /// No description provided for @generatingPlasma.
  ///
  /// In en, this message translates to:
  /// **'Generating Plasma'**
  String get generatingPlasma;

  /// No description provided for @hardwareWallet.
  ///
  /// In en, this message translates to:
  /// **'Hardware wallet'**
  String get hardwareWallet;

  /// No description provided for @importWallet.
  ///
  /// In en, this message translates to:
  /// **'Import wallet'**
  String get importWallet;

  /// No description provided for @importYourWallet.
  ///
  /// In en, this message translates to:
  /// **'Import your wallet'**
  String get importYourWallet;

  /// No description provided for @importingSeed.
  ///
  /// In en, this message translates to:
  /// **'Importing seed'**
  String get importingSeed;

  /// No description provided for @initializingWalletPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Initializing wallet, please wait'**
  String get initializingWalletPleaseWait;

  /// No description provided for @inputSeedOrImportSeedVault.
  ///
  /// In en, this message translates to:
  /// **'Input your seed or import the Seed Vault'**
  String get inputSeedOrImportSeedVault;

  /// No description provided for @inputSeedVaultKeyToContinue.
  ///
  /// In en, this message translates to:
  /// **'Input the Seed Vault Key to continue'**
  String get inputSeedVaultKeyToContinue;

  /// No description provided for @lastAttemptWalletWillReset.
  ///
  /// In en, this message translates to:
  /// **'Last attempt. The wallet will be reset if this attempt fails'**
  String get lastAttemptWalletWillReset;

  /// Displays a Ledger error prefix followed by the error details.
  ///
  /// In en, this message translates to:
  /// **'Ledger: {details}'**
  String ledgerWithDetails(String details);

  /// Displays a Ledger hardware device label with its name.
  ///
  /// In en, this message translates to:
  /// **'Ledger {name}'**
  String ledgerWithName(String name);

  /// No description provided for @mnemonicIsNotValid.
  ///
  /// In en, this message translates to:
  /// **'Mnemonic is not valid'**
  String get mnemonicIsNotValid;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @passwordRequiredToUnlockWallet.
  ///
  /// In en, this message translates to:
  /// **'This is the password that will be required to unlock the wallet'**
  String get passwordRequiredToUnlockWallet;

  /// No description provided for @plasmaGenerationIdle.
  ///
  /// In en, this message translates to:
  /// **'Plasma generation idle'**
  String get plasmaGenerationIdle;

  /// No description provided for @resolvingAddressConfirmOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Resolving address, please confirm the address on your hardware device'**
  String get resolvingAddressConfirmOnDevice;

  /// No description provided for @scanDevices.
  ///
  /// In en, this message translates to:
  /// **'Scan devices'**
  String get scanDevices;

  /// No description provided for @selectOptionToAccessWallet.
  ///
  /// In en, this message translates to:
  /// **'Select an option to access your wallet'**
  String get selectOptionToAccessWallet;

  /// No description provided for @selectToConnectDevice.
  ///
  /// In en, this message translates to:
  /// **'Select to connect the device'**
  String get selectToConnectDevice;

  /// Displays the word count of the newly generated wallet seed.
  ///
  /// In en, this message translates to:
  /// **'This is your {wordCount} words seed'**
  String thisIsYourWordsSeed(int wordCount);

  /// No description provided for @clickToBrowseOrDragAndDropFile.
  ///
  /// In en, this message translates to:
  /// **'Click to browse or drag and drop a file'**
  String get clickToBrowseOrDragAndDropFile;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @nodeInformationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Node information is unavailable'**
  String get nodeInformationUnavailable;

  /// No description provided for @someNodeInformationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Some node information is unavailable'**
  String get someNodeInformationUnavailable;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Unlock failed'**
  String get unlockFailed;

  /// No description provided for @unlockYourSeedVault.
  ///
  /// In en, this message translates to:
  /// **'Unlock your Seed Vault'**
  String get unlockYourSeedVault;

  /// No description provided for @unsupportedWalletFileType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported wallet file type'**
  String get unsupportedWalletFileType;

  /// No description provided for @walletSuccessfullyCreated.
  ///
  /// In en, this message translates to:
  /// **'The wallet has been successfully created'**
  String get walletSuccessfullyCreated;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @writeDownAndExportSeedSafely.
  ///
  /// In en, this message translates to:
  /// **'Please carefully write down your seed and export it to a safe location'**
  String get writeDownAndExportSeedSafely;

  /// No description provided for @writtenDownMySeed.
  ///
  /// In en, this message translates to:
  /// **'I have written down my seed'**
  String get writtenDownMySeed;

  /// No description provided for @youAreAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get youAreAllSet;
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
