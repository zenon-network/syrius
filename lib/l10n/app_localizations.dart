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

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cannotReuseAddressForSentinel.
  ///
  /// In en, this message translates to:
  /// **'If this address previously revoked a Sentinel, it cannot create a new Sentinel again. Use a different address before depositing QSR.'**
  String get cannotReuseAddressForSentinel;

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

  /// No description provided for @createAnotherToken.
  ///
  /// In en, this message translates to:
  /// **'Create another Token'**
  String get createAnotherToken;

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

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

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

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get minAgo;

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

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

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

  /// No description provided for @noP2pSwaps.
  ///
  /// In en, this message translates to:
  /// **'No P2P swaps'**
  String get noP2pSwaps;

  /// No description provided for @noRewardsCollect.
  ///
  /// In en, this message translates to:
  /// **'No rewards to collect'**
  String get noRewardsCollect;

  /// No description provided for @noZtsTokensAvailable.
  ///
  /// In en, this message translates to:
  /// **'No ZTS tokens available'**
  String get noZtsTokensAvailable;

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

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

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

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get showDetails;

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

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

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

  /// No description provided for @totalSupply.
  ///
  /// In en, this message translates to:
  /// **'Total supply'**
  String get totalSupply;

  /// No description provided for @transactionError.
  ///
  /// In en, this message translates to:
  /// **'Error while receiving transaction'**
  String get transactionError;

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

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @walletNotAutoLocked.
  ///
  /// In en, this message translates to:
  /// **'Your wallet will not be auto-locked while the swap is in progress.'**
  String get walletNotAutoLocked;

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
