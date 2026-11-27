import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/foundation.dart'
    show
        DiagnosticsNode,
        FlutterError,
        FlutterErrorDetails,
        FlutterExceptionHandler;
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'devnet_bdd_helpers.dart';
import 'devnet_test_context.dart';

/// ZNN amount sent to fund the freshly generated counterparty wallet.
const String kP2pSwapCounterpartyFundingZnn = '1';

P2pSwapDevnetContext? _activeP2pSwapContext;

/// Returns the active [P2pSwapDevnetContext] for the running scenario.
P2pSwapDevnetContext requireP2pSwapDevnetContext() {
  final P2pSwapDevnetContext? current = _activeP2pSwapContext;
  if (current == null) {
    throw StateError(
      'P2pSwapDevnetContext has not been initialized for this scenario',
    );
  }
  return current;
}

/// Manages isolated two-party wallet globals, Drift databases, and scenario
/// state for the devnet P2P HTLC swap BDD test.
class P2pSwapDevnetContext {
  P2pSwapDevnetContext._({
    required this.tempDirectory,
    required this.initiatorAddress,
    required this.counterpartyAddress,
    required this.counterpartyWalletFile,
    required this.initiatorStorage,
    required this.initiatorRepository,
    required this.counterpartyStorage,
    required this.counterpartyRepository,
    required this._savedWalletFile,
    required this._savedDefaultAddressList,
    required this._savedAddressLabelMap,
    required this._savedSelectedAddress,
    required this._savedNodeChainId,
    required this._savedHtlcSwapRepository,
    required this._savedHtlcSwapUnlockService,
    required this._savedDontWarnAboutMultipleDatabases,
  });

  /// Isolated temp directory storing the encrypted Drift SQLite databases.
  final Directory tempDirectory;

  /// Devnet address of the swap initiator (Wallet A, index 9).
  final String initiatorAddress;

  /// Freshly generated address of the swap counterparty (Wallet B).
  final String counterpartyAddress;

  /// In-memory wallet file backing the counterparty's separate seed.
  final DevnetWalletFile counterpartyWalletFile;

  /// Encrypted local storage backing the initiator's Drift DB.
  final HtlcSwapLocalStorageApi initiatorStorage;

  /// Initiator's isolated HTLC swap repository.
  final HtlcSwapRepository initiatorRepository;

  /// Encrypted local storage backing the counterparty's Drift DB.
  final HtlcSwapLocalStorageApi counterpartyStorage;

  /// Counterparty's isolated HTLC swap repository.
  final HtlcSwapRepository counterpartyRepository;

  final WalletFile? _savedWalletFile;
  final List<String?> _savedDefaultAddressList;
  final Map<String, String> _savedAddressLabelMap;
  final String? _savedSelectedAddress;
  final int? _savedNodeChainId;
  final HtlcSwapRepository? _savedHtlcSwapRepository;
  final HtlcSwapUnlockService? _savedHtlcSwapUnlockService;
  final bool _savedDontWarnAboutMultipleDatabases;

  HtlcSwapSyncService? _activeSyncService;
  bool _disposed = false;

  /// Persisted outgoing swap created by the initiator UI.
  HtlcSwap? initialSwap;

  /// Hash of the initial HTLC created on-chain.
  Hash? initialHtlcId;

  /// Amount of ZNN locked in the initial HTLC.
  BigInt? initialSwapAmount;

  /// Persisted incoming swap created by the counterparty Join UI.
  HtlcSwap? counterSwap;

  /// Hash of the counter-HTLC created on-chain.
  Hash? counterHtlcId;

  /// Amount of ZNN locked in the counter-HTLC.
  BigInt? counterSwapAmount;

  /// Published unlock account block created by the initiator Complete UI.
  AccountBlockTemplate? initiatorUnlockBlock;

  /// Confirmed `contractReceive` block for the initiator's unlock of the
  /// counter-HTLC.
  AccountBlock? initiatorUnlockContractReceive;

  /// Completed incoming swap persisted after the counterparty auto-unlocks.
  HtlcSwap? completedCounterpartySwap;

  /// Initializes a fresh two-party [P2pSwapDevnetContext] and registers
  /// teardown cleanup.
  static Future<P2pSwapDevnetContext> create() async {
    if (_activeP2pSwapContext != null) {
      await _activeP2pSwapContext!.dispose();
    }

    final WalletFile? savedWalletFile = kWalletFile;
    final List<String?> savedDefaultAddressList = List<String?>.from(
      kDefaultAddressList,
    );
    final Map<String, String> savedAddressLabelMap = Map<String, String>.from(
      kAddressLabelMap,
    );
    final String? savedSelectedAddress = kSelectedAddress;
    final int? savedNodeChainId = kNodeChainId;
    final HtlcSwapRepository? savedHtlcSwapRepository =
        app.sl.isRegistered<HtlcSwapRepository>()
        ? app.sl<HtlcSwapRepository>()
        : null;
    final HtlcSwapUnlockService? savedHtlcSwapUnlockService =
        app.sl.isRegistered<HtlcSwapUnlockService>()
        ? app.sl<HtlcSwapUnlockService>()
        : null;

    kNodeChainId = DevnetTestContext.chainId;

    final KeyStore counterpartyKeyStore = await KeyStore.newRandom();
    final WalletAccount counterpartyAccount = await counterpartyKeyStore
        .getAccount();
    final String counterpartyAddress = (await counterpartyAccount.getAddress())
        .toString();
    final DevnetWalletFile counterpartyWalletFile = DevnetWalletFile(
      counterpartyKeyStore,
    );

    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'syrius_devnet_p2p_swap_',
    );
    final HtlcSwapLocalStorageApi initiatorStorage = HtlcSwapLocalStorageApi(
      databaseFile: File('${tempDirectory.path}/initiator_htlc_swaps.sqlite'),
    );
    final HtlcSwapLocalStorageApi counterpartyStorage = HtlcSwapLocalStorageApi(
      databaseFile: File(
        '${tempDirectory.path}/counterparty_htlc_swaps.sqlite',
      ),
    );
    final List<int> initiatorKey = Crypto.digest(
      utf8.encode('devnet-p2p-swap-initiator-key'),
    );
    final List<int> counterpartyKey = Crypto.digest(
      utf8.encode('devnet-p2p-swap-counterparty-key'),
    );

    final bool savedDontWarnAboutMultipleDatabases =
        driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    try {
      await initiatorStorage.open(initiatorKey);
      await counterpartyStorage.open(counterpartyKey);
    } on Object {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases =
          savedDontWarnAboutMultipleDatabases;
      await initiatorStorage.close();
      await counterpartyStorage.close();
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
      rethrow;
    }

    final HtlcSwapRepository initiatorRepository = HtlcSwapRepository(
      chainIdProvider: () => kNodeChainId,
      dataProvider: initiatorStorage,
    );
    final HtlcSwapRepository counterpartyRepository = HtlcSwapRepository(
      chainIdProvider: () => kNodeChainId,
      dataProvider: counterpartyStorage,
    );

    final P2pSwapDevnetContext context = P2pSwapDevnetContext._(
      tempDirectory: tempDirectory,
      initiatorAddress: DevnetTestContext.fundedDevAddresses[9]!,
      counterpartyAddress: counterpartyAddress,
      counterpartyWalletFile: counterpartyWalletFile,
      initiatorStorage: initiatorStorage,
      initiatorRepository: initiatorRepository,
      counterpartyStorage: counterpartyStorage,
      counterpartyRepository: counterpartyRepository,
      savedWalletFile: savedWalletFile,
      savedDefaultAddressList: savedDefaultAddressList,
      savedAddressLabelMap: savedAddressLabelMap,
      savedSelectedAddress: savedSelectedAddress,
      savedNodeChainId: savedNodeChainId,
      savedHtlcSwapRepository: savedHtlcSwapRepository,
      savedHtlcSwapUnlockService: savedHtlcSwapUnlockService,
      savedDontWarnAboutMultipleDatabases: savedDontWarnAboutMultipleDatabases,
    );

    _activeP2pSwapContext = context;
    addTearDown(context.dispose);
    await context.activateInitiatorWallet();
    return context;
  }

  /// Switches wallet globals and GetIt registrations to the initiator wallet.
  Future<void> activateInitiatorWallet({String? selectedAddress}) async {
    kWalletFile = _savedWalletFile;
    kDefaultAddressList = List<String?>.from(_savedDefaultAddressList);
    kAddressLabelMap = Map<String, String>.from(_savedAddressLabelMap);
    kNodeChainId = DevnetTestContext.chainId;
    selectDevnetSender(selectedAddress ?? initiatorAddress);
    await _registerHtlcServices(initiatorRepository);
  }

  /// Switches wallet globals and GetIt registrations to the counterparty
  /// wallet.
  Future<void> activateCounterpartyWallet() async {
    kWalletFile = counterpartyWalletFile;
    kDefaultAddressList = <String?>[counterpartyAddress];
    kAddressLabelMap = <String, String>{counterpartyAddress: 'Counterparty 0'};
    kSelectedAddress = counterpartyAddress;
    kNodeChainId = DevnetTestContext.chainId;
    await _registerHtlcServices(counterpartyRepository);
  }

  /// Runs a real [HtlcSwapSyncService] against [repository] until
  /// [isReady] returns true, then stops the service cleanly.
  Future<HtlcSwap> syncUntilSwapReady({
    required HtlcSwapRepository repository,
    required String swapId,
    required bool Function(HtlcSwap? swap) isReady,
    required String description,
  }) async {
    final HtlcSwapUnlockService unlockService = HtlcSwapUnlockService(
      accountBlockUtils: AccountBlockUtils(publishSuccessNotification: false),
      zenon: app.zenon!,
    );
    final HtlcSwapAutoUnlockService autoUnlockService =
        HtlcSwapAutoUnlockService(
          notificationsBloc: app.sl<NotificationsBloc>(),
          syncMonitor: NodeSyncMonitor(zenon: app.zenon!),
          unlockService: unlockService,
        );
    final HtlcSwapSyncService syncService = HtlcSwapSyncService(
      swapRepository: repository,
      autoUnlockService: autoUnlockService,
      zenon: app.zenon!,
    );
    _activeSyncService = syncService;
    syncService.start();

    try {
      final HtlcSwap? swap = await pollDevnet<HtlcSwap?>(
        () => repository.getSwapById(swapId),
        isReady: isReady,
        description: description,
      );
      return swap!;
    } finally {
      await syncService.stop();
      if (identical(_activeSyncService, syncService)) {
        _activeSyncService = null;
      }
    }
  }

  /// Stops active services, closes temp Drift databases, deletes temp files,
  /// and restores original globals and GetIt registrations.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

    Object? firstError;
    StackTrace? firstStackTrace;
    void recordError(Object error, StackTrace stackTrace) {
      if (firstError == null) {
        firstError = error;
        firstStackTrace = stackTrace;
      }
    }

    try {
      try {
        await _activeSyncService?.stop();
      } on Object catch (error, stackTrace) {
        recordError(error, stackTrace);
      } finally {
        _activeSyncService = null;
      }

      try {
        await initiatorStorage.close();
      } on Object catch (error, stackTrace) {
        recordError(error, stackTrace);
      }

      try {
        await counterpartyStorage.close();
      } on Object catch (error, stackTrace) {
        recordError(error, stackTrace);
      }

      try {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      } on Object catch (error, stackTrace) {
        recordError(error, stackTrace);
      }
    } finally {
      try {
        if (app.sl.isRegistered<HtlcSwapRepository>()) {
          await app.sl.unregister<HtlcSwapRepository>();
        }
        if (_savedHtlcSwapRepository != null) {
          app.sl.registerSingleton<HtlcSwapRepository>(
            _savedHtlcSwapRepository,
          );
        }

        if (app.sl.isRegistered<HtlcSwapUnlockService>()) {
          await app.sl.unregister<HtlcSwapUnlockService>();
        }
        if (_savedHtlcSwapUnlockService != null) {
          app.sl.registerSingleton<HtlcSwapUnlockService>(
            _savedHtlcSwapUnlockService,
          );
        }
      } finally {
        kWalletFile = _savedWalletFile;
        kDefaultAddressList = List<String?>.from(_savedDefaultAddressList);
        kAddressLabelMap = Map<String, String>.from(_savedAddressLabelMap);
        kSelectedAddress = _savedSelectedAddress;
        kNodeChainId = _savedNodeChainId;
        driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            _savedDontWarnAboutMultipleDatabases;

        if (identical(_activeP2pSwapContext, this)) {
          _activeP2pSwapContext = null;
        }
      }
    }

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  Future<void> _registerHtlcServices(HtlcSwapRepository repository) async {
    if (app.sl.isRegistered<HtlcSwapRepository>()) {
      await app.sl.unregister<HtlcSwapRepository>();
    }
    app.sl.registerSingleton<HtlcSwapRepository>(repository);

    if (app.sl.isRegistered<HtlcSwapUnlockService>()) {
      await app.sl.unregister<HtlcSwapUnlockService>();
    }
    app.sl.registerSingleton<HtlcSwapUnlockService>(
      HtlcSwapUnlockService(
        accountBlockUtils: AccountBlockUtils(publishSuccessNotification: false),
        zenon: app.zenon!,
      ),
    );
  }
}

/// Ensures [targetAddress] has sufficient plasma for P2P swap transactions.
Future<void> ensureP2pSwapPlasma({
  required P2pSwapDevnetContext swapContext,
  required String targetAddress,
}) => ensureDevnetPlasma(
  targetAddress,
  prepareFuserWallet: () => swapContext.activateInitiatorWallet(
    selectedAddress: kDevnetPlasmaFuserAddress,
  ),
);

/// Sends [amountZnn] from the initiator to the counterparty and receives it on
/// the counterparty's account chain so the counterparty has confirmed funds.
Future<void> fundAndReceiveCounterpartyZnn({
  required P2pSwapDevnetContext swapContext,
  required String amountZnn,
}) async {
  final BigInt amount = amountZnn.extractDecimals(coinDecimals);
  final Address counterpartyAddress = Address.parse(
    swapContext.counterpartyAddress,
  );

  await swapContext.activateInitiatorWallet();
  final AccountBlockUtils accountBlockUtils = AccountBlockUtils(
    publishSuccessNotification: false,
  );
  final AccountBlockTemplate sendBlock = await accountBlockUtils
      .createAccountBlock(
        AccountBlockTemplate.send(counterpartyAddress, znnZts, amount),
        'fund p2p swap counterparty',
        address: Address.parse(swapContext.initiatorAddress),
        waitForRequiredPlasma: true,
      );

  await pollDevnet<AccountBlockList>(
    () => app.zenon!.ledger.getUnreceivedBlocksByAddress(counterpartyAddress),
    isReady: (AccountBlockList list) =>
        list.list?.any((AccountBlock block) => block.hash == sendBlock.hash) ??
        false,
    description:
        'unreceived funding block ${sendBlock.hash} for '
        '${swapContext.counterpartyAddress}',
  );

  await swapContext.activateCounterpartyWallet();
  await accountBlockUtils.createAccountBlock(
    AccountBlockTemplate.receive(sendBlock.hash),
    'receive p2p swap counterparty funding',
    address: counterpartyAddress,
    waitForRequiredPlasma: true,
  );

  await pollDevnet<AccountInfo>(
    () => app.zenon!.ledger.getAccountInfoByAddress(counterpartyAddress),
    isReady: (AccountInfo info) => info.getBalance(znnZts) >= amount,
    description:
        'confirmed ZNN balance >= $amount for '
        '${swapContext.counterpartyAddress}',
  );
}

/// Polls until the HTLC embedded contract has a confirmed `contractReceive`
/// block paired with [sendBlockHash].
Future<AccountBlock> waitForConfirmedHtlcContractReceive(
  Hash sendBlockHash, {
  required String description,
}) async {
  final AccountBlock? match = await pollDevnet<AccountBlock?>(
    () async {
      final AccountBlockList page = await app.zenon!.ledger
          .getAccountBlocksByPage(htlcAddress, pageSize: 50);
      for (final AccountBlock block in page.list ?? const <AccountBlock>[]) {
        if (block.blockType == BlockTypeEnum.contractReceive.index &&
            block.pairedAccountBlock?.hash == sendBlockHash &&
            block.confirmationDetail?.momentumTimestamp != null) {
          return block;
        }
      }
      return null;
    },
    isReady: (AccountBlock? block) => block != null,
    description: description,
  );
  return match!;
}

/// Polls until the HTLC embedded contract has a confirmed `contractReceive`
/// block for an `Unlock` call targeting [htlcId].
Future<AccountBlock> waitForConfirmedHtlcUnlockReceiveByHtlcId(
  Hash htlcId, {
  required String description,
}) async {
  final AccountBlock? match = await pollDevnet<AccountBlock?>(
    () async {
      final AccountBlockList page = await app.zenon!.ledger
          .getAccountBlocksByPage(htlcAddress, pageSize: 50);
      for (final AccountBlock block in page.list ?? const <AccountBlock>[]) {
        final AccountBlock? paired = block.pairedAccountBlock;
        if (block.blockType != BlockTypeEnum.contractReceive.index ||
            paired == null ||
            block.confirmationDetail?.momentumTimestamp == null) {
          continue;
        }
        final BlockData? data = decodeHtlcBlockData(paired.data);
        if (data?.function == 'Unlock' &&
            data?.params['id'].toString() == htlcId.toString()) {
          return block;
        }
      }
      return null;
    },
    isReady: (AccountBlock? block) => block != null,
    description: description,
  );
  return match!;
}

/// Polls until [app.zenon!.embedded.htlc.getById] fails with the node's
/// `data non existent` RPC error for [htlcId], proving the HTLC has been
/// removed on-chain without mistaking transport errors for removal.
Future<void> waitForHtlcRemoved(Hash htlcId) async {
  await pollDevnet<bool>(
    () async {
      try {
        await app.zenon!.embedded.htlc.getById(htlcId);
        return false;
      } on RpcException catch (error) {
        if (error.message.toLowerCase().contains('data non existent')) {
          return true;
        }
        rethrow;
      }
    },
    isReady: (bool removed) => removed,
    description: 'HTLC $htlcId to be removed on-chain after unlock',
  );
}

/// Polls until [recipient] has an unreceived payout block matching one of the
/// descendant blocks of [unlockContractReceive] with [expectedToken] and
/// [expectedAmount].
Future<AccountBlock> waitForHtlcPayoutUnreceivedBlock({
  required Address recipient,
  required TokenStandard expectedToken,
  required BigInt expectedAmount,
  required AccountBlock unlockContractReceive,
}) async {
  final Set<Hash> descendantHashes = unlockContractReceive.descendantBlocks
      .map((AccountBlock block) => block.hash)
      .toSet();
  expect(
    descendantHashes,
    isNotEmpty,
    reason:
        'Expected unlock contractReceive block '
        '${unlockContractReceive.hash} to emit a payout descendant block',
  );

  final AccountBlock? payout = await pollDevnet<AccountBlock?>(
    () async {
      final AccountBlockList list = await app.zenon!.ledger
          .getUnreceivedBlocksByAddress(recipient);
      for (final AccountBlock block in list.list ?? const <AccountBlock>[]) {
        if (descendantHashes.contains(block.hash) &&
            block.address == htlcAddress &&
            block.toAddress == recipient &&
            block.tokenStandard == expectedToken &&
            block.amount == expectedAmount) {
          return block;
        }
      }
      return null;
    },
    isReady: (AccountBlock? block) => block != null,
    description:
        'unreceived HTLC payout descendant of ${unlockContractReceive.hash} '
        'for $expectedAmount ($expectedToken) to $recipient',
  );
  return payout!;
}

/// Decodes an HTLC ABI call payload from [encodedData].
BlockData? decodeHtlcBlockData(List<int> encodedData) =>
    AccountBlockUtils.getDecodedBlockData(Definitions.htlc, encodedData);

/// Runs [action] while ignoring only the known debug-mode `RenderFlex`
/// overflow emitted by `InstructionButton`'s `AnimatedCrossFade` when its
/// `LoadingInfoText` (`Row`, height 24) is constrained to the narrower idle
/// label width.
///
/// All other Flutter errors (including overflows from any other widget) are
/// forwarded unchanged to the active handler.
Future<T> runIgnoringInstructionButtonCrossFadeOverflow<T>(
  Future<T> Function() action,
) async {
  final FlutterExceptionHandler? previousHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isInstructionButtonLoadingOverflow(details)) {
      return;
    }
    if (previousHandler != null) {
      previousHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  try {
    return await action();
  } finally {
    FlutterError.onError = previousHandler;
  }
}

bool _isInstructionButtonLoadingOverflow(FlutterErrorDetails details) {
  if (details.library != 'rendering library' ||
      !details.exceptionAsString().startsWith('A RenderFlex overflowed by ')) {
    return false;
  }

  final Iterable<DiagnosticsNode>? nodes = details.informationCollector?.call();
  if (nodes == null) {
    return false;
  }

  final StringBuffer buffer = StringBuffer();
  for (final DiagnosticsNode node in nodes) {
    buffer.writeln(node.toDescription());
    for (final DiagnosticsNode property in node.getProperties()) {
      // Avoid calling Flutter's widget-inspector creator transform on defunct
      // elements, which throws "Looking up a deactivated widget's ancestor is
      // unsafe". Raw DiagnosticsNode values still carry creator/size strings.
      if (property.name == 'creator') {
        buffer.writeln('${property.name}: ${property.value}');
      }
    }
  }
  final String summary = buffer.toString();
  // InstructionButton is the only widget in the app that renders
  // LoadingInfoText inside an AnimatedCrossFade. Require both identifiers so
  // unrelated AnimatedCrossFade or disposed RenderFlex overflows are never
  // suppressed.
  return summary.contains('LoadingInfoText') &&
      (summary.contains('InstructionButton') ||
          summary.contains('AnimatedCrossFade'));
}
