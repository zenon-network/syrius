import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/handlers/htlc_swaps_handler.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/keystore_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class InitUtils {
  static Future<void> initApp(BuildContext context) async {
    try {
      WidgetUtils.setThemeMode(context);
      WidgetUtils.setTextScale(context);
      _setAutoEraseWalletNumAttempts();
      _setAutoLockWalletTimeInterval();
      await KeyStoreUtils.setKeyStorePath();
      await _setNumUnlockFailedAttempts();
      await NodeUtils.setNode();
      _setChainId();
      await NodeUtils.loadDbNodes();
    } catch (e) {
      rethrow;
    }
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

  static Future<void> initWalletAfterDecryption() async {
    await AddressUtils.setAddresses(kKeyStore);
    await AddressUtils.setAddressLabels();
    await AddressUtils.setDefaultAddress();
    zenon!.defaultKeyPair = kKeyStore!.getKeyPair(
      kDefaultAddressList.indexOf(kSelectedAddress),
    );
    await _openFavoriteTokensBox();
    await _openNotificationsBox();
    await _openRecipientBox();
    await NodeUtils.initWebSocketClient();
    await _setWalletVersion();
    final baseAddress = await kKeyStore!.getKeyPair(0).address;
    await htlcSwapsService!.openBoxes(
        baseAddress.toString(), kKeyStore!.getKeyPair(0).getPrivateKey()!);
    sl<HtlcSwapsHandler>().start();
    kWalletInitCompleted = true;
  }

  static Future<void> _openFavoriteTokensBox() async =>
      await Hive.openBox(kFavoriteTokensBox);

  static Future<void> _openNotificationsBox() async =>
      await Hive.openBox(kNotificationsBox);

  static Future<void> _openRecipientBox() async =>
      await Hive.openBox(kRecipientAddressBox);

  static Future<void> _setWalletVersion() async => sharedPrefsService!.put(
        kWalletVersionKey,
        kWalletVersion,
      );
}
