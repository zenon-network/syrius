import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SetAddressArguments {
  final KeyStore? keystore;
  final SendPort port;

  SetAddressArguments(this.keystore, this.port);
}

class ZenonAddressUtils {
  static void refreshBalance() =>
      sl.get<BalanceBloc>().getBalanceForAllAddresses();

  static String getLabel(String address) =>
      kAddressLabelMap[address] ?? address;

  static Future<void> generateNewAddress(
      {int numAddr = 1, VoidCallback? callback}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    List<Address?> listAddr = [];
    int addrListLength = kDefaultAddressList.length;
    for (int i = 0; i < numAddr; i++) {
      int addrListCounter = addrListLength + i;
      Address? address = await kKeyStore!.getKeyPair(addrListCounter).address;
      listAddr.add(address);
      Box addressesBox = Hive.box(kAddressesBox);
      await addressesBox.add(listAddr.elementAt(i).toString());
      _initAddresses(addressesBox);
      Box addressLabelsBox = Hive.box(kAddressLabelsBox);
      await addressLabelsBox.put(
        listAddr.elementAt(i).toString(),
        'Address ${kDefaultAddressList.length}',
      );
      _initAddressLabels(addressLabelsBox);
      NodeUtils.getUnreceivedTransactionsByAddress(listAddr[i]!);
      callback?.call();
    }
    listAddr.clear();
  }

  static Future<void> setAddressLabels() async {
    Box addressLabelsBox = await Hive.openBox(kAddressLabelsBox);

    if (addressLabelsBox.isEmpty) {
      for (var address in kDefaultAddressList) {
        await addressLabelsBox.put(
            address, 'Address ${kDefaultAddressList.indexOf(address) + 1}');
      }
    }
    _initAddressLabels(addressLabelsBox);
  }

  static void setAddressesFunction(SetAddressArguments args) async {
    for (var element in (await Future.wait(
      List<Future<String>>.generate(
          kNumOfInitialAddresses,
          (index) async =>
              (await args.keystore!.getKeyPair(index).address).toString()),
    ))) {
      args.port.send(element);
    }
    args.port.send('done');
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

  static Future<void> setAddresses(KeyStore? keyStore) async {
    final port = ReceivePort();
    Box addressesBox = await Hive.openBox(kAddressesBox);
    final args = SetAddressArguments(keyStore, port.sendPort);
    if (addressesBox.isEmpty) {
      Isolate.spawn<SetAddressArguments>(
        setAddressesFunction,
        args,
        onError: port.sendPort,
        onExit: port.sendPort,
      );
      StreamSubscription? sub;
      Completer completer = Completer<void>();
      sub = port.listen(
        (data) async {
          if (data != null && data != 'done') {
            addressesBox.add(data);
          } else if (data == 'done') {
            _initAddresses(addressesBox);
            completer.complete();
            await sub?.cancel();
          }
        },
      );
      return completer.future;
    } else {
      _initAddresses(addressesBox);
    }
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
