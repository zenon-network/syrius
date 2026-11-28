import 'package:flutter/cupertino.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Notifies listeners of the most recently detected WalletConnect URI.
ValueNotifier<String?> kLastWalletConnectUriNotifier = ValueNotifier<String?>(
  null,
);

/// Currently selected Zenon node URL or embedded node identifier.
String? kCurrentNode;

/// Currently selected wallet address string.
String? kSelectedAddress;

/// Filesystem path of the active encrypted wallet file.
String? kWalletPath;

/// Detected local IP address of the host machine.
String? kLocalIpAddress;

/// Inactivity timeout in minutes before automatically locking the wallet.
int? kAutoLockWalletMinutes;

/// Chain identifier reported by the connected Zenon node.
int? kNodeChainId;

/// Number of consecutive failed wallet unlock attempts.
int? kNumFailedUnlockAttempts;

/// Maximum failed unlock attempts allowed before erasing the wallet.
double? kAutoEraseWalletLimit;

/// Whether auto-erasing the wallet after failed unlock attempts is enabled.
bool? kAutoEraseWalletEnabled;

/// Whether post-decryption wallet initialization has completed.
bool kWalletInitCompleted = false;

/// Currently unlocked wallet file handle, or `null` when locked.
WalletFile? kWalletFile;

/// User-configured node URLs loaded from local storage.
List<String> kDbNodes = <String>[];

/// Derived wallet addresses loaded from local storage.
List<String?> kDefaultAddressList = <String?>[];

/// Mapping from wallet address strings to user-defined labels.
Map<String, String> kAddressLabelMap = <String, String>{};

/// Currently active navigation tab.
Tabs? kCurrentPage;

/// Complete ordered list of navigation tabs.
final List<Tabs> kTabs = <Tabs>[...kTabsWithTextTitles, ...kTabsWithIconTitles];

/// Cached total number of network Pillars.
int? kNumOfPillars;

/// Whether the embedded full node isolate is currently running.
bool kEmbeddedNodeRunning = false;

/// Navigation tabs displayed with icon titles in the sidebar.
final List<Tabs> kTabsWithIconTitles = <Tabs>[
  if (kWcProjectId.isNotEmpty) Tabs.walletConnect,
  Tabs.accelerator,
  Tabs.help,
  Tabs.notifications,
  Tabs.settings,
  Tabs.generation,
  Tabs.sync,
  Tabs.lock,
];

/// Navigation tabs that are currently non-interactive status indicators.
final List<Tabs> kDisabledTabs = <Tabs>[
  Tabs.generation,
  Tabs.sync,
];

/// Built-in default node options available before user customization.
List<String> kDefaultNodes = <String>[
  kEmbeddedNode,
  kLocalhostDefaultNodeUrl,
];

/// Community-supplied public RPC node URLs.
List<String> kDefaultCommunityNodes = <String>[];
