import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:version/version.dart';
import 'package:zenon_syrius_wallet_flutter/handlers/htlc_swaps_handler.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class InitUtils {
  static Future<void> initApp(BuildContext context) async {
    WidgetUtils.setThemeMode(context);
    WidgetUtils.setTextScale(context);
    _setAutoEraseWalletNumAttempts();
    _setAutoLockWalletTimeInterval();
    await WalletUtils.setWalletPath();
    await _setNumUnlockFailedAttempts();
    await NodeUtils.setNode();
    _setChainId();
    await NodeUtils.loadDbNodes();
    await _openFavoriteTokensBox();
    await _openNotificationsBox();
    await _openRecipientBox();
  }

  static void _setChainId() {
    setChainIdentifier(
      chainIdentifier: sharedPrefsService!.get(
        kChainIdKey,
        defaultValue: kChainIdDefaultValue,
      ),
    );
  }

  static Future<void> _setNumUnlockFailedAttempts() async {
    if (sharedPrefsService == null) {
      sharedPrefsService = await sl.getAsync<SharedPrefsService>();
    } else {
      await sharedPrefsService!.checkIfBoxIsOpen();
    }

    if (sharedPrefsService!.get(kNumUnlockFailedAttemptsKey) == null) {
      await sharedPrefsService!.put(
        kNumUnlockFailedAttemptsKey,
        0,
      );
    }
    kNumFailedUnlockAttempts =
        sharedPrefsService!.get(kNumUnlockFailedAttemptsKey);
  }

  static void _setAutoEraseWalletNumAttempts() =>
      kAutoEraseWalletLimit = sharedPrefsService!.get(
        kAutoEraseNumAttemptsKey,
        defaultValue: kAutoEraseNumAttemptsDefault,
      );

  static void _setAutoLockWalletTimeInterval() =>
      kAutoLockWalletMinutes = sharedPrefsService!.get(
        kAutoLockWalletMinutesKey,
        defaultValue: kAutoLockWalletDefaultIntervalMinutes,
      );

  static Future<void> initWalletAfterDecryption(List<int> cipherKey) async {
    final walletVersion = Version.parse(sharedPrefsService!
        .get(kWalletVersionKey, defaultValue: kWalletVersion),);
    await ZenonAddressUtils.setAddresses(kWalletFile);
    await ZenonAddressUtils.setAddressLabels();
    await ZenonAddressUtils.setDefaultAddress();
    await NodeUtils.initWebSocketClient();
    await _setWalletVersion();
    if (walletVersion <= Version(0, 1, 0)) {
      // Migrate to password as the cipherkey instead of the private key.
      await kWalletFile!.access((Wallet wallet) async {
        await htlcSwapsService!.openBoxes(WalletUtils.baseAddress.toString(),
            (wallet as KeyStore).getKeyPair().getPrivateKey()!,
            newCipherKey: cipherKey,);
      });
    } else {
      await htlcSwapsService!
          .openBoxes(WalletUtils.baseAddress.toString(), cipherKey);
    }
    sl<HtlcSwapsHandler>().start();
    kWalletInitCompleted = true;
  }

  static Future<void> _openFavoriteTokensBox() async =>
      Hive.openBox(kFavoriteTokensBox);

  static Future<void> _openNotificationsBox() async =>
      Hive.openBox(kNotificationsBox);

  static Future<void> _openRecipientBox() async =>
      Hive.openBox(kRecipientAddressBox);

  static Future<void> _setWalletVersion() async => sharedPrefsService!.put(
        kWalletVersionKey,
        kWalletVersion,
      );
}
