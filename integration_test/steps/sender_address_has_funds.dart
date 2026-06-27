import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: sender address {'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e'} has funds
Future<void> senderAddressHasFunds(
  WidgetTester tester,
  String senderAddress,
) async {
  HydratedBloc.storage = InMemoryHydratedStorage();
  _registerTestServices();

  final KeyStore wallet = KeyStore.fromMnemonic(
    devnetEnv('ZNN_TEST_MNEMONIC', DevnetTestContext.defaultMnemonic),
  );

  final Address derivedSenderAddress = Address.parse(senderAddress);

  await _configureWalletGlobals(wallet, derivedSenderAddress);

  final AccountInfo accountInfo = await app.zenon!.ledger.getAccountInfoByAddress(
    derivedSenderAddress,
  );
  expect(accountInfo.getBalance(znnZts), greaterThan(BigInt.zero));
}

void _registerTestServices() {
  if (!app.sl.isRegistered<Zenon>()) {
    app.sl.registerSingleton<Zenon>(app.zenon!);
  }
  if (!app.sl.isRegistered<NotificationsBloc>()) {
    app.sl.registerSingleton<NotificationsBloc>(TestNotificationsBloc());
  }
  if (!app.sl.isRegistered<BalanceBloc>()) {
    app.sl.registerSingleton<BalanceBloc>(BalanceBloc());
  }
  if (!app.sl.isRegistered<MultipleBalanceBloc>()) {
    app.sl.registerSingleton<MultipleBalanceBloc>(
      MultipleBalanceBloc(zenon: app.zenon!),
    );
  }
  if (!app.sl.isRegistered<PowGeneratingStatusBloc>()) {
    app.sl.registerSingleton<PowGeneratingStatusBloc>(PowGeneratingStatusBloc());
  }
}

Future<void> _configureWalletGlobals(
  KeyStore wallet,
  Address senderAddress,
) async {
  final int maxIndex = 9;
  final List<String> addresses = <String>[];

  for (int i = 0; i <= maxIndex; i += 1) {
    final WalletAccount account = await wallet.getAccount(i);
    addresses.add((await account.getAddress()).toString());
  }

  kWalletFile = DevnetWalletFile(wallet);
  kSelectedAddress = senderAddress.toString();
  kDefaultAddressList = addresses;
  kAddressLabelMap = <String, String>{
    for (int i = 0; i < addresses.length; i += 1) addresses[i]: 'Address $i',
  };
  kWalletInitCompleted = true;
}
