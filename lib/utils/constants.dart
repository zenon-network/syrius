import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_display/model/display_settings_enums.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

// WalletConnect
/// WalletConnect / Reown relay project identifier.
const String kWcProjectId = '6106aa8c2f308b338f31465bef999a1f';

/// WalletConnect namespace used for Zenon Network sessions.
const String kZenonNameSpace = 'zenon';

/// Directory name used to store local WalletConnect state.
const String walletConnectDirName = 'walletconnect';

// Dimensions
/// Height of the token amount input suffix widget.
const double kAmountSuffixHeight = 25;

/// Width of the token amount input suffix widget.
const double kAmountSuffixWidth = 40;

/// Corner radius of the token amount input suffix widget.
const double kAmountSuffixRadius = 5;

/// Default inner padding for content containers.
const double kContentPadding = 8;

/// Width of each seed phrase word grid cell.
const double kSeedWordCellWidth = 200;

/// Width of password text input fields.
const double kPasswordInputFieldWidth = 360;

// Size widgets
/// Minimum dimensions for loading action buttons.
const Size kLoadingButtonMinSize = Size(120, 40);

/// Minimum dimensions for settings action buttons.
const Size kSettingsButtonMinSize = Size(100, 35);

/// Standard vertical spacer between form sections.
const SizedBox kVerticalSpacing = SizedBox(
  height: 15,
);

/// Standard horizontal spacer between paired action buttons.
const SizedBox kSpacingBetweenActionButtons = SizedBox(
  width: 70,
);

/// Size of Accelerator-Z project voting progress bars.
const Size kAcceleratorProgressBarSize = Size(300, 10);

// Wallet version
/// Syrius wallet version displayed in About and saved under
/// [kWalletVersionKey].
const String kWalletVersion = '0.2.5';

// Boxes constants
/// Hive box name storing user-favorited token standards.
const String kFavoriteTokensBox = 'favourite_tokens_box';

/// Hive box name storing derived wallet addresses.
const String kAddressesBox = 'addresses_box';

/// Hive box name storing address-to-label mappings.
const String kAddressLabelsBox = 'address_labels_box';

/// Hive box name storing persisted wallet notifications.
const String kNotificationsBox = 'notifications_box';

/// Hive box name storing saved recipient addresses.
const String kRecipientAddressBox = 'recipient_address_box';

/// Hive box name storing general key-value preferences.
const String kSharedPrefsBox = 'shared_prefs_box';

/// Hive box name storing user-added node URLs.
const String kNodesBox = 'nodes_box';

/// Hive box name storing the active keystore file path.
const String kKeyStoreBox = 'key_store_box';

/// Legacy Hive box name for HTLC swaps prior to Drift migration.
const String kHtlcSwapsBox = 'htlc_swaps_box';

/// Hive box name storing the last scanned HTLC momentum/block marker.
const String kLastCheckedHtlcBlockBox = 'last_checked_htlc_block_box';

/// SQLite database filename for encrypted HTLC P2P swaps.
const String kHtlcSwapsDatabase = 'htlc_swaps.sqlite';

/// Hive cache boxes deleted during the delete-cache flow and wallet reset.
const List<String> kCacheBoxesToBeDeleted = <String>[
  kFavoriteTokensBox,
  kAddressesBox,
  kAddressLabelsBox,
  kNotificationsBox,
  kRecipientAddressBox,
  kSharedPrefsBox,
  kNodesBox,
  kLastCheckedHtlcBlockBox,
];

// Wallet file name
/// Default filename used when saving a keystore wallet.
const String kNameWalletFile = 'wallet';

// Github Syrius releases link
/// URL of the latest GitHub releases page for Syrius.
const String kGithubReleasesLink =
    'https://github.com/zenon-network/syrius/releases/latest';

/// Notification title shown when wallet decryption fails due to wrong password.
const String kIncorrectPasswordNotificationTitle = 'Incorrect password';

/// Notification title shown when wallet unlock fails for another reason.
const String kUnlockFailedNotificationTitle = 'Unlock failed';

/// Default date formatting pattern.
const String kDefaultDateFormat = 'dd MMMM, yyyy';

/// Default date and time formatting pattern.
const String kDefaultDateTimeFormat = 'yyyy-MM-dd hh:mm a';

// Key-value store
/// Shared preferences key for the selected text scaling mode.
const String kTextScalingKey = 'text_scaling_key';

/// Shared preferences key for the selected Zenon node URL.
const String kSelectedNodeKey = 'selected_node_key';

/// Shared preferences key for the default active wallet address.
const String kDefaultAddressKey = 'default_address';

/// Shared preferences key for the stored wallet version string.
const String kWalletVersionKey = 'wallet_version_key';

/// Shared preferences key for consecutive failed unlock attempts.
const String kNumUnlockFailedAttemptsKey = 'num_unlock_failed_attempts';

/// Legacy shared preferences key for the entropy/keystore file path.
const String kEntropyFilePathKey = 'entropy_file_path_key';

/// Shared preferences key for saved desktop window width.
const String kWindowSizeWidthKey = 'window_size_width_key';

/// Shared preferences key for saved desktop window height.
const String kWindowSizeHeightKey = 'window_size_height_key';

/// Shared preferences key for saved desktop window X coordinate.
const String kWindowPositionXKey = 'window_position_x_key';

/// Shared preferences key for saved desktop window Y coordinate.
const String kWindowPositionYKey = 'window_position_y_key';

/// Shared preferences key for whether the desktop window is maximized.
const String kWindowMaximizedKey = 'window_maximized_key';

/// Shared preferences key for enabling automatic P2P HTLC unlocks.
const String kP2pAtomicUnlockKey = 'p2p_atomic_unlock_key';

/// Shared preferences key for enabling automatic P2P HTLC reclaims.
const String kP2pAutoReclaimKey = 'p2p_auto_reclaim_key';

/// Legacy key for the last checked HTLC block height inside
/// [kLastCheckedHtlcBlockBox] (referenced only by
/// `legacy_htlc_swaps_migrator_test.dart`).
const String kLastCheckedHtlcBlockKey = 'last_checked_htlc_block_key';

/// Default border width for outlined containers and inputs.
const double kDefaultBorderOutlineWidth = 1;

// TODO(maznnwell): to change to int
/// Default number of days plotted in dashboard charts.
const double kStandardChartNumDays = 7;

/// Maximum character length permitted for an address label.
const int kAddressLabelMaxLength = 80;

/// Number of addresses automatically derived when initializing a new wallet.
const int kNumOfInitialAddresses = 1;

/// Number of rows in the mnemonic seed confirmation grid.
const int kSeedGridNumOfRows = 4;

/// Number of mnemonic words the user must confirm during wallet creation.
const int kNumOfSeedWordsToBeFound = 6;

/// Number of seconds in one hour.
const int kOneHourInSeconds = 3600;

/// Expected number of Zenon momentums produced per hour.
const int kMomentumsPerHour = kOneHourInSeconds ~/ kSecondsPerMomentum;

/// Number of hours in one day.
const int kHoursPerDay = 24;

/// Expected number of Zenon momentums produced per day.
const int kMomentumsPerDay = kHoursPerDay * kMomentumsPerHour;

/// Number of days in one week.
const int kDaysInAWeek = 7;

/// Expected number of Zenon momentums produced per week.
const int kMomentumsPerWeek = kMomentumsPerDay * kDaysInAWeek;

/// Plasma required for Pillar registration and management transactions.
const int kPillarPlasmaAmountNeeded = 252000;

/// Plasma required for Sentinel registration transactions.
const int kSentinelPlasmaAmountNeeded = 252000;

/// Plasma required for staking transactions.
const int kStakePlasmaAmountNeeded = 105000;

/// Plasma required for delegation transactions.
const int kDelegatePlasmaAmountNeeded = 84000;

/// Plasma required for ZTS token issuance transactions.
const int kIssueTokenPlasmaAmountNeeded = 189000;

/// Maximum character length allowed in token amount text inputs.
const int kAmountInputMaxCharacterLength = 21;

/// Target block interval in seconds between Zenon momentums.
const int kSecondsPerMomentum = 10;

/// Maximum number of P2P swap records retained locally.
const int kMaxP2pSwapsToStore = 500;

/// Plasma thresholds relevant to regular wallet users.
const List<int> kNormalUsersPlasmaRequirements = <int>[
  kStakePlasmaAmountNeeded,
  kDelegatePlasmaAmountNeeded,
];

/// Plasma thresholds relevant to power-user operations.
const List<int> kPowerUsersPlasmaRequirements = <int>[
  kPillarPlasmaAmountNeeded,
  kSentinelPlasmaAmountNeeded,
  kIssueTokenPlasmaAmountNeeded,
];

/// Placeholder value of `kCurrentNode` that selects the bundled embedded node.
const String kEmbeddedNode = 'Embedded Node';

/// Default localhost WebSocket URL used to connect to the embedded node.
const String kLocalhostDefaultNodeUrl = 'ws://127.0.0.1:$kDefaultPort';

/// Default WebSocket RPC port for a Zenon node.
const int kDefaultPort = 35998;

/// Identifiers for core wallet staking and network actions.
const List<String> kWalletActions = <String>[
  'pillar',
  'sentinel',
  'delegation',
  'stake',
  'plasma',
];

// Notifications constants
/// Maximum number of notifications fetched per page/query.
const int kNotificationsResultLimit = 100;

/// Maximum total notification records stored in Hive.
const int kNotificationsEntriesLimit = 10000;

/// Time formatting pattern used on notification entries.
const String kNotificationsTimeFormat = 'hh:mm aaa';

/// Hive TypeAdapter ID for `WalletNotification`.
const int kWalletNotificationHiveTypeId = 100;

/// Hive TypeAdapter ID for `NotificationType`.
const int kNotificationTypeEnumHiveTypeId = 101;

// Community links
/// Official Zenon Network website URL.
const String kWebsite = 'https://zenon.network';

/// Zenon.org community website URL.
const String kOrgCommunityWebsite = 'https://zenon.org';

/// Zenon.org community forum URL.
const String kOrgCommunityForum = 'https://forum.zenon.org';

/// ZenonHub community website URL.
const String kHubCommunityWebsite = 'https://zenonhub.io';

/// ZenonHub block explorer URL.
const String kHubCommunityExplorer = 'https://zenonhub.io/explorer';

/// Official Zenon Network Twitter/X profile URL.
const String kTwitter = 'https://twitter.com/Zenon_Network';

/// Official Zenon Network Telegram group URL.
const String kTelegram = 'https://t.me/zenonnetwork';

/// Official Zenon Network GitHub organization URL.
const String kGithub = 'https://github.com/zenon-network';

/// Official Zenon Network block explorer URL.
const String kExplorer = 'https://explorer.zenon.network';

/// Official Zenon Network wiki URL.
const String kWiki = 'https://wiki.zenon.network';

/// Zenon.org community documentation URL.
const String kOrgCommunityWiki = 'https://docs.zenon.org';

/// Zenon Tools ecosystem dashboard URL.
const String kTools = 'https://zenon.tools';

/// Direct URL to the Zenon Network whitepaper PDF.
const String kWhitepaper =
    'https://github.com/zenon-network/zenon.network/releases/download/whitepaper/whitepaper.pdf';

/// URL to the latest `znn_controller_dart` releases page.
const String kZnnController =
    'https://github.com/zenon-network/znn_controller_dart/releases/latest';

/// URL to the Zenon Network BitcoinTalk announcement thread.
const String kBitcoinTalk =
    'https://bitcointalk.org/index.php?topic=5279643.msg55303681#msg55303681';

/// Official Zenon Network Discord invite URL.
const String kDiscord = 'https://discord.gg/zenonnetwork';

/// Official Zenon Network Medium publication URL.
const String kMedium = 'https://medium.com/@zenon.network';

/// Official Zenon Network subreddit URL.
const String kReddit = 'https://reddit.com/r/Zenon_Network';

/// Official Zenon Network YouTube channel URL.
const String kYoutube = 'https://youtube.com/channel/UCDb8ZtqBt6l5l4HugCnJwhQ';

// Wallet security
/// Default failed unlock attempt limit before erasing the wallet.
const double kAutoEraseNumAttemptsDefault = 3;

/// Default inactivity timeout in minutes before auto-locking the wallet.
const int kAutoLockWalletDefaultIntervalMinutes = 15;

/// Shared preferences key for the wallet auto-lock interval in minutes.
const String kAutoLockWalletMinutesKey = 'auto_lock_interval_minutes';

/// Shared preferences key for the wallet auto-erase failed attempt threshold.
const String kAutoEraseNumAttemptsKey = 'auto_erase_num_attempts';

// Wallet preferences
/// Shared preferences key for launching Syrius at OS login.
const String kLaunchAtStartupKey = 'launch_at_startup';

/// Shared preferences key for enabling OS desktop notifications.
const String kEnableDesktopNotificationsKey = 'enable_desktop_notifications';

/// Shared preferences key for enabling the clipboard WalletConnect watcher.
const String kEnableClipboardWatcherKey = 'enable_clipboard_watcher';

/// Shared preferences key for enabling automatic receiving of transactions.
const String kAutoReceiveKey = 'enable_auto_receive';

/// Default value for [kLaunchAtStartupKey].
const bool kLaunchAtStartupDefaultValue = false;

/// Default value for [kEnableDesktopNotificationsKey].
const bool kEnableDesktopNotificationsDefaultValue = false;

/// Default value for [kEnableClipboardWatcherKey].
const bool kEnableClipboardWatcherDefaultValue = false;

/// Default value for [kAutoReceiveKey].
const bool kAutoReceiveDefaultValue = true;

/// Shared preferences key for the configured Zenon chain identifier.
const String kChainIdKey = 'chain_id';

/// Default Zenon chain identifier (`1` corresponds to Alphanet).
const int kChainIdDefaultValue = 1;

// Display constants
/// Shared preferences key for the selected [ThemeMode].
const String kThemeModeKey = 'theme_mode_key';

/// Default application [ThemeMode].
const ThemeMode kDefaultThemeMode = ThemeMode.dark;

/// Default application [TextScaling] setting.
const TextScaling kDefaultTextScaling = TextScaling.system;

/// Color mapping for user send and receive block types.
const Map<BlockTypeEnum, Color> kBlockTypeColorMap = <BlockTypeEnum, Color>{
  BlockTypeEnum.userReceive: AppColors.darkHintTextColor,
  BlockTypeEnum.userSend: AppColors.lightHintTextColor,
};

// Duration constants
/// Cooldown duration after account block creation calls.
const Duration kDelayAfterAccountBlockCreationCall = Duration(
  seconds: 31,
);

/// Voting window duration for Accelerator-Z projects and phases.
const Duration kProjectVotingPeriod = Duration(days: 14);

/// Delay before attempting to connect to a newly spawned embedded node.
const Duration kEmbeddedConnectionDelay = Duration(seconds: 30);

// Tabs
/// Primary navigation tabs rendered with text labels.
const List<Tabs> kTabsWithTextTitles = <Tabs>[
  Tabs.dashboard,
  Tabs.transfer,
  Tabs.pillars,
  Tabs.sentinels,
  Tabs.staking,
  Tabs.plasma,
  Tabs.tokens,
  Tabs.p2pSwap,
];

// P2P swap constants
/// Default lock duration for an initiator's initial HTLC.
const Duration kInitialHtlcDuration = Duration(
  hours: 8,
);

/// Default lock duration for a counterparty's counter HTLC.
const Duration kCounterHtlcDuration = Duration(hours: 1);

/// Maximum permitted lock duration for an initial HTLC.
const Duration kMaxAllowedInitialHtlcDuration = Duration(hours: 24);

/// Minimum remaining time considered safe for discovering an HTLC preimage.
const Duration kMinSafeTimeToFindPreimage = Duration(hours: 6);

/// Minimum remaining time considered safe to complete a swap unlock.
const Duration kMinSafeTimeToCompleteSwap = Duration(minutes: 10);

/// Shared preferences key tracking acknowledgement of the P2P swap warning.
const String kHasReadP2pSwapWarningKey = 'has_read_p2p_swap_warning';

/// Default value for [kHasReadP2pSwapWarningKey].
const bool kHasReadP2pSwapWarningDefaultValue = false;

/// URL of the P2P atomic swap tutorial article.
const String kP2pSwapTutorialLink =
    'https://medium.com/@vilkris/p2p-swap-tutorial-3805f10d2d21';
