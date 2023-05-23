import 'dart:io';

import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

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
