import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_local_storage_api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/legacy_htlc_swaps_migrator.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_sync_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Utilities for bootstrapping application and wallet state at startup.
class InitUtils {
  /// Initializes display settings, preferences, node configuration, and Hive
  /// boxes before unlocking the wallet.
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
    kNumFailedUnlockAttempts = sharedPrefsService!.get(
      kNumUnlockFailedAttemptsKey,
    );
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

  /// Initializes addresses, WebSocket connectivity, and encrypted swap storage
  /// after the wallet has been decrypted with [cipherKey].
  static Future<void> initWalletAfterDecryption(List<int> cipherKey) async {
    await ZenonAddressUtils.setAddresses(kWalletFile);
    await ZenonAddressUtils.setAddressLabels();
    await ZenonAddressUtils.setDefaultAddress();
    if (sl.isRegistered<IWeb3WalletService>()) {
      sl<IWeb3WalletService>().registerAccountsIfNeeded();
    }
    await NodeUtils.initWebSocketClient();
    await sl<HtlcSwapLocalStorageApi>().open(cipherKey);
    await sl<LegacyHtlcSwapsMigrator>().migrateIfNeeded(
      walletBaseAddress: WalletUtils.baseAddress.toString(),
      encryptionKey: cipherKey,
    );
    await _setWalletVersion();
    sl<HtlcSwapSyncService>().start();
    kWalletInitCompleted = true;
  }

  static Future<void> _openFavoriteTokensBox() =>
      Hive.openBox<dynamic>(kFavoriteTokensBox);

  static Future<void> _openNotificationsBox() =>
      Hive.openBox<dynamic>(kNotificationsBox);

  static Future<void> _openRecipientBox() =>
      Hive.openBox<dynamic>(kRecipientAddressBox);

  static Future<void> _setWalletVersion() => sharedPrefsService!.put(
    kWalletVersionKey,
    kWalletVersion,
  );
}
