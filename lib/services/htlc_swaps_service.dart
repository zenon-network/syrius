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

  Future<void> openBoxes(String htlcSwapsBoxSuffix, List<int> cipherKey) async {
    if (_htlcSwapsBox == null || !_htlcSwapsBox!.isOpen) {
      _htlcSwapsBox = await Hive.openBox('${kHtlcSwapsBox}_$htlcSwapsBoxSuffix',
          encryptionCipher: HiveAesCipher(cipherKey));
    }

    if (_lastCheckedHtlcBlockHeightBox == null ||
        !_lastCheckedHtlcBlockHeightBox!.isOpen) {
      _lastCheckedHtlcBlockHeightBox = await Hive.openBox(
          kLastCheckedHtlcBlockBox,
          encryptionCipher: HiveAesCipher(cipherKey));
    }
  }

  List<HtlcSwap> getAllSwaps() {
    return _swapsForCurrentChainId;
  }

  List<HtlcSwap> getSwapsByState(List<P2pSwapState> states) {
    return _swapsForCurrentChainId
        .where((e) => states.contains(e.state))
        .toList();
  }

  HtlcSwap? getSwapByHashLock(String hashLock) {
    try {
      return _swapsForCurrentChainId
          .firstWhereOrNull((e) => e.hashLock == hashLock);
    } on HiveError {
      return null;
    }
  }

  HtlcSwap? getSwapByHtlcId(String htlcId) {
    try {
      return _swapsForCurrentChainId.firstWhereOrNull(
          (e) => e.initialHtlcId == htlcId || e.counterHtlcId == htlcId);
    } on HiveError {
      return null;
    }
  }

  HtlcSwap? getSwapById(String id) {
    try {
      return _swapsForCurrentChainId.firstWhereOrNull((e) => e.id == id);
    } on HiveError {
      return null;
    }
  }

  int getLastCheckedHtlcBlockHeight() {
    return _lastCheckedHtlcBlockHeightBox!
        .get(kLastCheckedHtlcBlockKey, defaultValue: 0);
  }

  Future<void> storeSwap(HtlcSwap swap) async => await _htlcSwapsBox!
      .put(
        swap.id,
        jsonEncode(swap.toJson()),
      )
      .then((_) async => await _pruneSwapsHistoryIfNeeded());

  Future<void> storeLastCheckedHtlcBlockHeight(int height) async =>
      await _lastCheckedHtlcBlockHeightBox!
          .put(kLastCheckedHtlcBlockKey, height);

  Future<void> deleteSwap(String swapId) async =>
      await _htlcSwapsBox!.delete(swapId);

  Future<void> deleteInactiveSwaps() async =>
      await _htlcSwapsBox!.deleteAll(_swapsForCurrentChainId
          .where((e) => [
                P2pSwapState.completed,
                P2pSwapState.unsuccessful,
                P2pSwapState.error
              ].contains(e.state))
          .map((e) => e.id));

  List<HtlcSwap> get _swapsForCurrentChainId {
    return kNodeChainId != null
        ? _htlcSwapsBox!.values
            .where(
                (e) => HtlcSwap.fromJson(jsonDecode(e)).chainId == kNodeChainId)
            .map((e) => HtlcSwap.fromJson(jsonDecode(e)))
            .toList()
        : [];
  }

  HtlcSwap? _getOldestPrunableSwap() {
    final swaps = getAllSwaps()
        .where((e) => [P2pSwapState.completed, P2pSwapState.unsuccessful]
            .contains(e.state))
        .toList();
    swaps.sort((a, b) => b.startTime.compareTo(a.startTime));
    return swaps.isNotEmpty ? swaps.last : null;
  }

  Future<void> _pruneSwapsHistoryIfNeeded() async {
    if (_htlcSwapsBox!.length > kMaxP2pSwapsToStore) {
      final toBePruned = _getOldestPrunableSwap();
      if (toBePruned != null) {
        await deleteSwap(toBePruned.id);
      }
    }
  }
}
