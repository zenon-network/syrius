import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ZenonAddressUtils {
  static void refreshBalance() =>
      sl.get<BalanceBloc>().getBalanceForAllAddresses();

  static String getLabel(String address) =>
      kAddressLabelMap[address] ?? address;

  static Future<void> generateNewAddress(
      {int numAddr = 1, VoidCallback? callback,}) async {
    final wallet = await kWalletFile!.open();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final listAddr = <Address?>[];
      final addrListLength = kDefaultAddressList.length;
      for (var i = 0; i < numAddr; i++) {
        final addrListCounter = addrListLength + i;
        final walletAccount = await wallet.getAccount(addrListCounter);
        Address? address;
        if (walletAccount is LedgerWalletAccount) {
          await sl.get<NotificationsBloc>().addNotification(
                WalletNotification(
                  title:
                      'Adding address, please confirm the address on your hardware device',
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  details:
                      'Confirm address for account index: $addrListCounter',
                  type: NotificationType.confirm,
                ),
              );
          address = await walletAccount.getAddress(true);
        } else {
          address = await walletAccount.getAddress();
        }
        listAddr.add(address);
        final addressesBox = Hive.box(kAddressesBox);
        await addressesBox.add(listAddr.elementAt(i).toString());
        _initAddresses(addressesBox);
        final addressLabelsBox = Hive.box(kAddressLabelsBox);
        await addressLabelsBox.put(
          listAddr.elementAt(i).toString(),
          'Address ${kDefaultAddressList.length}',
        );
        _initAddressLabels(addressLabelsBox);
        NodeUtils.getUnreceivedTransactionsByAddress(listAddr[i]!);
        callback?.call();
      }
      listAddr.clear();
    } catch (e) {
      await NotificationUtils.sendNotificationError(
          e, 'Error while generating new address',);
    } finally {
      kWalletFile!.close();
    }
  }

  static Future<void> setAddressLabels() async {
    final addressLabelsBox = await Hive.openBox(kAddressLabelsBox);

    if (addressLabelsBox.isEmpty) {
      for (final address in kDefaultAddressList) {
        await addressLabelsBox.put(
            address, 'Address ${kDefaultAddressList.indexOf(address) + 1}',);
      }
    }
    _initAddressLabels(addressLabelsBox);
  }

  static Future<void> setDefaultAddress() async {
    if (sharedPrefsService!.get(kDefaultAddressKey) == null) {
      await sharedPrefsService!.put(
        kDefaultAddressKey,
        kDefaultAddressList[0],
      );
    }
    kSelectedAddress = sharedPrefsService!.get(kDefaultAddressKey);
  }

  static Future<void> setAddresses(WalletFile? walletFile) async {
    final addressesBox = await Hive.openBox(kAddressesBox);
    if (addressesBox.isEmpty) {
      await walletFile!.access((wallet) async {
        for (final element in await Future.wait(
          List<Future<String>>.generate(
              kNumOfInitialAddresses,
              (index) async =>
                  (await (await wallet.getAccount(index)).getAddress())
                      .toString(),),
        )) {
          addressesBox.add(element);
        }
      });
    }
    _initAddresses(addressesBox);
  }

  static void _initAddresses(Box addressesBox) =>
      kDefaultAddressList = List<String?>.from(addressesBox.values);

  static void _initAddressLabels(Box box) =>
      kAddressLabelMap = box.keys.toList().fold<Map<String, String>>(
        {},
        (previousValue, key) {
          previousValue[key] = box.get(key);
          return previousValue;
        },
      );
}
