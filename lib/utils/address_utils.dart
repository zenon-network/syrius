import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Utilities for managing wallet addresses, labels, and address balances.
class ZenonAddressUtils {
  /// Triggers a balance refresh for all derived wallet addresses.
  void refreshBalance() {
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      ),
    );
  }

  /// Returns the user-assigned label for [address], or [address] itself when
  /// no label is set.
  static String getLabel(String address) =>
      kAddressLabelMap[address] ?? address;

  /// Derives and persists [numAddr] new wallet addresses, invoking [callback]
  /// after each address is added.
  static Future<void> generateNewAddress({
    int numAddr = 1,
    VoidCallback? callback,
  }) async {
    final WalletFile? walletFile = kWalletFile;
    if (walletFile == null) {
      throw LocalizedSyriusException(SyriusErrorCode.walletNotUnlocked);
    }
    await walletFile.access<void>((Wallet wallet) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final List<Address?> listAddr = <Address?>[];
      final int addrListLength = kDefaultAddressList.length;
      for (int i = 0; i < numAddr; i++) {
        final int addrListCounter = addrListLength + i;
        final WalletAccount walletAccount = await wallet.getAccount(
          addrListCounter,
        );
        Address? address;
        if (walletAccount is LedgerWalletAccount) {
          await sl.get<NotificationsBloc>().addNotification(
            WalletNotification(
              title:
                  'Adding address, please confirm the address on your '
                  'hardware device',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Confirm address for account index: $addrListCounter',
              type: NotificationType.confirm,
            ),
          );
          address = await walletAccount.getAddress(true);
        } else {
          address = await walletAccount.getAddress();
        }
        listAddr.add(address);
        final Box<dynamic> addressesBox = Hive.box<dynamic>(kAddressesBox);
        await addressesBox.add(listAddr.elementAt(i).toString());
        _initAddresses(addressesBox);

        final Box<dynamic> addressLabelsBox = Hive.box<dynamic>(
          kAddressLabelsBox,
        );
        await addressLabelsBox.put(
          listAddr.elementAt(i).toString(),
          'Address ${kDefaultAddressList.length}',
        );
        _initAddressLabels(addressLabelsBox);
        unawaited(
          NodeUtils.getUnreceivedTransactionsByAddress(listAddr[i]!),
        );
        callback?.call();
      }
      sl.get<MultipleBalanceBloc>().add(
        MultipleBalanceFetch(
          addresses: kDefaultAddressList.map((String? e) => e!).toList(),
        ),
      );
      listAddr.clear();
    });
  }

  /// Opens the address labels box, populates defaults if empty, and loads
  /// [kAddressLabelMap].
  static Future<void> setAddressLabels() async {
    final Box<dynamic> addressLabelsBox = await Hive.openBox<dynamic>(
      kAddressLabelsBox,
    );

    if (addressLabelsBox.isEmpty) {
      for (final String? address in kDefaultAddressList) {
        await addressLabelsBox.put(
          address,
          'Address ${kDefaultAddressList.indexOf(address) + 1}',
        );
      }
    }
    _initAddressLabels(addressLabelsBox);
  }

  /// Initializes [kSelectedAddress] from persisted preferences, defaulting to
  /// the first wallet address.
  static Future<void> setDefaultAddress() async {
    if (sharedPrefsService!.get(kDefaultAddressKey) == null) {
      await sharedPrefsService!.put(kDefaultAddressKey, kDefaultAddressList[0]);
    }
    kSelectedAddress = sharedPrefsService!.get(kDefaultAddressKey);
  }

  /// Opens the addresses box, derives initial addresses from [walletFile] if
  /// empty, and loads [kDefaultAddressList].
  static Future<void> setAddresses(WalletFile? walletFile) async {
    final Box<dynamic> addressesBox = await Hive.openBox<dynamic>(
      kAddressesBox,
    );
    if (addressesBox.isEmpty) {
      await walletFile!.access<void>((Wallet wallet) async {
        final List<String> addresses = await Future.wait<String>(
          List<Future<String>>.generate(
            kNumOfInitialAddresses,
            (int index) async => (await (await wallet.getAccount(
              index,
            )).getAddress()).toString(),
          ),
        );
        for (final String element in addresses) {
          await addressesBox.add(element);
        }
      });
    }
    _initAddresses(addressesBox);
  }

  static void _initAddresses(Box<dynamic> addressesBox) =>
      kDefaultAddressList = List<String?>.from(addressesBox.values);

  static void _initAddressLabels(Box<dynamic> box) =>
      kAddressLabelMap = box.keys.toList().fold<Map<String, String>>(
        <String, String>{},
        (Map<String, String> previousValue, dynamic key) {
          previousValue[key] = box.get(key);
          return previousValue;
        },
      );
}
