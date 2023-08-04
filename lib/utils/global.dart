import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

ValueNotifier<String?> kLastWalletConnectUriNotifier = ValueNotifier(null);
String? kCurrentNode;
String? kSelectedAddress;
String? kKeyStorePath;
String? kLocalIpAddress;

int? kAutoLockWalletMinutes;
int? kNodeChainId;
int? kNumFailedUnlockAttempts;

double? kAutoEraseWalletLimit;

bool kWalletInitCompleted = false;

KeyStore? kKeyStore;

KeyStoreManager kKeyStoreManager = KeyStoreManager(
  walletPath: Directory(kKeyStorePath!),
);

List<String> kDbNodes = [];
List<String?> kDefaultAddressList = [];

Map<String, String> kAddressLabelMap = {};

Tabs? kCurrentPage;

final List<Tabs> kTabs = [...kTabsWithTextTitles, ...kTabsWithIconTitles];

WalletNotification? kLastNotification;
WalletNotification? kLastDismissedNotification;

int? kNumOfPillars;

bool kEmbeddedNodeRunning = false;

final List<Tabs> kTabsWithIconTitles = [
  Tabs.bridge,
  if (kWcProjectId.isNotEmpty) Tabs.walletConnect,
  Tabs.accelerator,
  Tabs.help,
  Tabs.notifications,
  Tabs.settings,
  Tabs.resyncWallet,
  Tabs.lock,
];

final List<Tabs> kDisabledTabs = [
  Tabs.resyncWallet,
];
