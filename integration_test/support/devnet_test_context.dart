import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Directory? _hiveDirectory;

class DevnetTestContext {
  static const int chainId = 69;
  static const int defaultSenderIndex = 3;
  static const int defaultRecipientIndex = 8;
  static const String defaultNodeUrl = 'ws://localhost:35998';
  static const String defaultPassword = 'devnet';
  static const String defaultMnemonic =
      'abstract affair idle position alien fluid board ordinary exist afraid '
      'chapter wood wood guide sun walnut crew perfect place firm poverty '
      'model side million';
  static const String testPillarOwnerAddress =
      'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e';
  static const String testPillarName = 'testPillar';
  static const String testPillarRewardAddress =
      'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e';
  static const String testPillarProducerAddress =
      'z1qzh6xyndzcuagylguxxlyp6s6kxz7lgh9zx093';
  static const int testPillarMomentumReward = 30;
  static const int testPillarDelegationReward = 55;
  static const String testPillarSetupQsrFuseAmount = '120';

  static const Map<int, String> fundedDevAddresses = <int, String>{
    1: 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
    3: 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e',
    8: 'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth',
    9: 'z1qqcam4ycu0ta8333hx38r5j2z3ry9jjfxkc7t5',
  };

  static String get defaultSenderAddress =>
      fundedDevAddresses[defaultSenderIndex]!;

  AccountBlockTemplate? sentBlock;
  AccountBlockTemplate? plasmaFuseBlock;
  AccountBlockTemplate? pillarQsrDepositBlock;
  AccountBlockTemplate? deployPillarBlock;
  AccountBlockTemplate? stakeBlock;
  BigInt? plasmaFuseAmount;
  BigInt? pillarQsrDepositAmount;
}

Future<void> initializeDevnetIntegrationTests() async {
  await _initializeSharedPrefs();
  app.zenon ??= Zenon();
  if (app.sl.isRegistered<DevnetTestContext>()) {
    await app.sl.unregister<DevnetTestContext>();
  }
  app.sl.registerSingleton<DevnetTestContext>(DevnetTestContext());

  final String nodeUrl = devnetEnv(
    'ZNN_TEST_NODE_URL',
    DevnetTestContext.defaultNodeUrl,
  );
  final bool connected = await app.zenon!.wsClient
      .initialize(nodeUrl, retry: false)
      .timeout(const Duration(seconds: 15));

  expect(
    connected,
    isTrue,
    reason: 'Could not connect to devnet at $nodeUrl',
  );

  final Momentum momentum = await app.zenon!.ledger.getFrontierMomentum();
  expect(
    momentum.chainIdentifier,
    DevnetTestContext.chainId,
    reason:
        'Integration tests must run against docker devnet chain ID '
        '${DevnetTestContext.chainId}',
  );
  setChainIdentifier(chainIdentifier: momentum.chainIdentifier);

  HydratedBloc.storage = InMemoryHydratedStorage();
  _registerTestServices();

  final KeyStore wallet = KeyStore.fromMnemonic(
    devnetEnv('ZNN_TEST_MNEMONIC', DevnetTestContext.defaultMnemonic),
  );
  await _configureWalletGlobals(wallet);
}

void resetDevnetScenarioState() {
  app.sl<DevnetTestContext>()
    ..sentBlock = null
    ..plasmaFuseBlock = null
    ..pillarQsrDepositBlock = null
    ..deployPillarBlock = null
    ..stakeBlock = null
    ..plasmaFuseAmount = null
    ..pillarQsrDepositAmount = null;
  selectDevnetSender(DevnetTestContext.defaultSenderAddress);
}

void selectDevnetSender(String senderAddress) {
  if (!kDefaultAddressList.contains(senderAddress)) {
    throw StateError(
      'Sender address $senderAddress is not in the devnet wallet',
    );
  }
  kSelectedAddress = senderAddress;
}

Future<void> disposeDevnetIntegrationTests() async {
  app.zenon?.wsClient.stop();
  await app.sharedPrefsService?.close();
  app.sharedPrefsService = null;
  if (app.sl.isRegistered<SharedPrefsService>()) {
    await app.sl.unregister<SharedPrefsService>();
  }
  await Hive.close();
  _hiveDirectory?.deleteSync(recursive: true);
  _hiveDirectory = null;
}

String devnetEnv(String name, String fallback) {
  final String dartDefineValue = String.fromEnvironment(name);
  if (dartDefineValue.isNotEmpty) {
    return dartDefineValue;
  }

  final String? platformValue = Platform.environment[name];
  return platformValue == null || platformValue.isEmpty
      ? fallback
      : platformValue;
}

Future<void> _initializeSharedPrefs() async {
  _hiveDirectory ??= Directory.systemTemp.createTempSync(
    'syrius_devnet_integration_',
  );
  Hive.init(_hiveDirectory!.path);
  app.sharedPrefsService = await SharedPrefsService.getInstance();
  if (app.sl.isRegistered<SharedPrefsService>()) {
    await app.sl.unregister<SharedPrefsService>();
  }
  app.sl.registerSingleton<SharedPrefsService>(app.sharedPrefsService!);
}

class DevnetWalletFile extends WalletFile {
  DevnetWalletFile(this._wallet) : super('devnet-memory-wallet');

  final Wallet _wallet;
  bool _isOpen = false;

  @override
  bool get isHardwareWallet => false;

  @override
  bool get isOpen => _isOpen;

  @override
  String get walletType => keyStoreWalletType;

  @override
  Future<Wallet> open() async {
    _isOpen = true;
    return _wallet;
  }

  @override
  void close() {
    _isOpen = false;
  }
}

class InMemoryHydratedStorage implements Storage {
  final Map<String, dynamic> _storage = <String, dynamic>{};

  @override
  Future<void> clear() async => _storage.clear();

  @override
  Future<void> close() async {}

  @override
  Future<void> delete(String key) async => _storage.remove(key);

  @override
  dynamic read(String key) => _storage[key];

  @override
  Future<void> write(String key, dynamic value) async => _storage[key] = value;
}

class TestNotificationsBloc extends NotificationsBloc {
  @override
  Future<void> addNotification(WalletNotification? notification) async {
    addEvent(notification);
  }

  @override
  Future<void> sendPlasmaNotification(String purposeOfGeneratingPlasma) async {}
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
    app.sl.registerSingleton<PowGeneratingStatusBloc>(
      PowGeneratingStatusBloc(),
    );
  }
}

Future<void> _configureWalletGlobals(KeyStore wallet) async {
  const int maxIndex = 9;
  final List<String> addresses = <String>[];

  for (int i = 0; i <= maxIndex; i += 1) {
    final WalletAccount account = await wallet.getAccount(i);
    addresses.add((await account.getAddress()).toString());
  }

  kWalletFile = DevnetWalletFile(wallet);
  kDefaultAddressList = addresses;
  kAddressLabelMap = <String, String>{
    for (int i = 0; i < addresses.length; i += 1) addresses[i]: 'Address $i',
  };
  kWalletInitCompleted = true;
  selectDevnetSender(DevnetTestContext.defaultSenderAddress);
}
