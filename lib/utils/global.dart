import 'package:flutter/cupertino.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

ValueNotifier<String?> kLastWalletConnectUriNotifier = ValueNotifier(null);
String? kCurrentNode;
String? kSelectedAddress;
String? kWalletPath;
String? kLocalIpAddress;

int? kAutoLockWalletMinutes;
int? kNodeChainId;
int? kNumFailedUnlockAttempts;

double? kAutoEraseWalletLimit;

bool kWalletInitCompleted = false;

WalletFile? kWalletFile;

List<String> kDbNodes = <String>[];
List<String?> kDefaultAddressList = <String?>[];

Map<String, String> kAddressLabelMap = <String, String>{};

Tabs? kCurrentPage;

final List<Tabs> kTabs = <Tabs>[...kTabsWithTextTitles, ...kTabsWithIconTitles];

WalletNotification? kLastNotification;
WalletNotification? kLastDismissedNotification;

int? kNumOfPillars;

bool kEmbeddedNodeRunning = false;

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

final List<Tabs> kDisabledTabs = <Tabs>[
  Tabs.generation,
  Tabs.sync,
];

List<String> kDefaultNodes = <String>[
  kEmbeddedNode,
  kLocalhostDefaultNodeUrl,
];

// Community supplied public rpc nodes
List<String> kDefaultCommunityNodes = <String>[];