import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class HtlcSwapsService {
  static Box? _htlcSwapsBox;
  static Box? _lastCheckedHtlcBlockHeightBox;

  static HtlcSwapsService? _instance;

  static HtlcSwapsService getInstance() {
    _instance ??= HtlcSwapsService();
    return _instance!;
  }

  bool get isMaxSwapsReached => _htlcSwapsBox!.length >= kMaxP2pSwapsToStore;

  Future<void> openBoxes(String htlcSwapsBoxSuffix, List<int> cipherKey,
      {List<int>? newCipherKey,}) async {
    if (_htlcSwapsBox == null || !_htlcSwapsBox!.isOpen) {
      _htlcSwapsBox = await Hive.openBox('${kHtlcSwapsBox}_$htlcSwapsBoxSuffix',
          encryptionCipher: HiveAesCipher(cipherKey),);
      if (newCipherKey != null) {
        final Map values = _htlcSwapsBox!.toMap();
        await _htlcSwapsBox!.deleteFromDisk();
        _htlcSwapsBox = await Hive.openBox(
            '${kHtlcSwapsBox}_$htlcSwapsBoxSuffix',
            encryptionCipher: HiveAesCipher(newCipherKey),);
        _htlcSwapsBox!.putAll(values);
        _htlcSwapsBox!.flush();
      }
    }

    if (_lastCheckedHtlcBlockHeightBox == null ||
        !_lastCheckedHtlcBlockHeightBox!.isOpen) {
      _lastCheckedHtlcBlockHeightBox = await Hive.openBox(
          kLastCheckedHtlcBlockBox,
          encryptionCipher: HiveAesCipher(cipherKey),);
      if (newCipherKey != null) {
        final Map values = _lastCheckedHtlcBlockHeightBox!.toMap();
        await _lastCheckedHtlcBlockHeightBox!.deleteFromDisk();
        _lastCheckedHtlcBlockHeightBox = await Hive.openBox(
            kLastCheckedHtlcBlockBox,
            encryptionCipher: HiveAesCipher(newCipherKey),);
        _lastCheckedHtlcBlockHeightBox!.putAll(values);
        _lastCheckedHtlcBlockHeightBox!.flush();
      }
    }
  }

  Future<void> closeBoxes() async {
    if (_htlcSwapsBox != null && _htlcSwapsBox!.isOpen) {
      await _htlcSwapsBox!.close();
      _htlcSwapsBox = null;
    }
    if (_lastCheckedHtlcBlockHeightBox != null &&
        _lastCheckedHtlcBlockHeightBox!.isOpen) {
      await _lastCheckedHtlcBlockHeightBox!.close();
      _lastCheckedHtlcBlockHeightBox = null;
    }
  }

  List<HtlcSwap> getAllSwaps() {
    return _swapsForCurrentChainId;
  }

  List<HtlcSwap> getSwapsByState(List<P2pSwapState> states) {
    return _swapsForCurrentChainId
        .where((HtlcSwap e) => states.contains(e.state))
        .toList();
  }

  HtlcSwap? getSwapByHashLock(String hashLock) {
    try {
      return _swapsForCurrentChainId
          .firstWhereOrNull((HtlcSwap e) => e.hashLock == hashLock);
    } on HiveError {
      return null;
    }
  }

  HtlcSwap? getSwapByHtlcId(String htlcId) {
    try {
      return _swapsForCurrentChainId.firstWhereOrNull(
          (HtlcSwap e) => e.initialHtlcId == htlcId || e.counterHtlcId == htlcId,);
    } on HiveError {
      return null;
    }
  }

  HtlcSwap? getSwapById(String id) {
    try {
      return _swapsForCurrentChainId.firstWhereOrNull((HtlcSwap e) => e.id == id);
    } on HiveError {
      return null;
    }
  }

  int getLastCheckedHtlcBlockHeight() {
    return _lastCheckedHtlcBlockHeightBox!
        .get(kLastCheckedHtlcBlockKey, defaultValue: 0);
  }

  Future<void> storeSwap(HtlcSwap swap) async => _htlcSwapsBox!
      .put(
        swap.id,
        jsonEncode(swap.toJson()),
      )
      .then((_) async => _pruneSwapsHistoryIfNeeded());

  Future<void> storeLastCheckedHtlcBlockHeight(int height) async =>
      _lastCheckedHtlcBlockHeightBox!
          .put(kLastCheckedHtlcBlockKey, height);

  Future<void> deleteSwap(String swapId) async =>
      _htlcSwapsBox!.delete(swapId);

  Future<void> deleteInactiveSwaps() async =>
      _htlcSwapsBox!.deleteAll(_swapsForCurrentChainId
          .where((HtlcSwap e) => <P2pSwapState>[
                P2pSwapState.completed,
                P2pSwapState.unsuccessful,
                P2pSwapState.error,
              ].contains(e.state),)
          .map((HtlcSwap e) => e.id),);

  List<HtlcSwap> get _swapsForCurrentChainId {
    return kNodeChainId != null
        ? _htlcSwapsBox!.values
            .where(
                (e) => HtlcSwap.fromJson(jsonDecode(e)).chainId == kNodeChainId,)
            .map((e) => HtlcSwap.fromJson(jsonDecode(e)))
            .toList()
        : <HtlcSwap>[];
  }

  HtlcSwap? _getOldestPrunableSwap() {
    final List<HtlcSwap> swaps = getAllSwaps()
        .where((HtlcSwap e) => <P2pSwapState>[P2pSwapState.completed, P2pSwapState.unsuccessful]
            .contains(e.state),)
        .toList();
    swaps.sort((HtlcSwap a, HtlcSwap b) => b.startTime.compareTo(a.startTime));
    return swaps.isNotEmpty ? swaps.last : null;
  }

  Future<void> _pruneSwapsHistoryIfNeeded() async {
    if (_htlcSwapsBox!.length > kMaxP2pSwapsToStore) {
      final HtlcSwap? toBePruned = _getOldestPrunableSwap();
      if (toBePruned != null) {
        await deleteSwap(toBePruned.id);
      }
    }
  }
}
