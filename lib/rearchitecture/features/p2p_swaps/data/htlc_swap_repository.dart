import 'dart:convert';

import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_local_storage_api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/p2p_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

/// Persists and queries HTLC swaps for the active chain.
class HtlcSwapRepository extends P2pSwapRepository<HtlcSwap> {
  /// Creates a repository backed by the provided local storage API.
  HtlcSwapRepository({
    required this._chainIdProvider,
    required this._dataProvider,
  });

  final int? Function() _chainIdProvider;
  final HtlcSwapLocalStorageApi _dataProvider;

  @override
  Future<List<HtlcSwap>> getAllSwaps() async {
    final List<HtlcSwapEntry> entries = await _dataProvider
        .readAllSwapEntries();
    return entries.map(_decodeSwap).toList();
  }

  @override
  Stream<List<HtlcSwap>> watchAllSwaps() => _dataProvider
      .watchAllSwapEntries()
      .map((List<HtlcSwapEntry> entries) => entries.map(_decodeSwap).toList());

  @override
  Future<List<HtlcSwap>> getSwapsByState(List<P2pSwapState> states) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null || states.isEmpty) {
      return <HtlcSwap>[];
    }

    final List<HtlcSwapEntry> entries = await _dataProvider
        .readSwapEntriesByState(
          chainId,
          states.map((P2pSwapState state) => state.name).toList(),
        );
    return entries.map(_decodeSwap).toList();
  }

  /// Returns the active chain's swap with [hashLock], if one exists.
  Future<HtlcSwap?> getSwapByHashLock(String hashLock) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return null;
    }

    return _decodeNullableSwap(
      await _dataProvider.readSwapEntryByHashLock(chainId, hashLock),
    );
  }

  /// Returns the active chain's swap containing [htlcId], if one exists.
  Future<HtlcSwap?> getSwapByHtlcId(String htlcId) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return null;
    }

    return _decodeNullableSwap(
      await _dataProvider.readSwapEntryByHtlcId(chainId, htlcId),
    );
  }

  @override
  Future<HtlcSwap?> getSwapById(String id) async =>
      _decodeNullableSwap(await _dataProvider.readSwapEntryById(id));

  /// Returns the last processed HTLC block height for the active chain.
  Future<int> getLastCheckedHtlcBlockHeight() {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return Future<int>.value(0);
    }

    return _dataProvider.readLastCheckedHtlcBlockHeight(chainId);
  }

  @override
  Future<void> storeSwap(HtlcSwap swap) => _dataProvider.writeSwapEntry(
    _encodeSwap(swap),
    maximumStoredSwaps: kMaxP2pSwapsToStore,
    pruneChainId: _chainIdProvider(),
    prunableStates: <String>[
      P2pSwapState.completed.name,
      P2pSwapState.unsuccessful.name,
    ],
  );

  /// Atomically inserts [swaps] whose ids do not already exist, without
  /// overwriting existing swaps or pruning history.
  Future<void> storeMissingSwaps(List<HtlcSwap> swaps) =>
      _dataProvider.insertMissingSwapEntries(swaps.map(_encodeSwap).toList());

  /// Stores the last processed HTLC block [height] for [chainId], or the
  /// active chain when [chainId] is omitted.
  Future<void> storeLastCheckedHtlcBlockHeight(
    int height, {
    int? chainId,
  }) async {
    final int? targetChainId = chainId ?? _chainIdProvider();
    if (targetChainId == null) {
      throw StateError('Cannot store an HTLC checkpoint without a chain id');
    }

    await _dataProvider.writeLastCheckedHtlcBlockHeight(targetChainId, height);
  }

  /// Stores a processed block checkpoint and its optional swap update.
  Future<void> storeProcessedHtlcBlock({
    required int height,
    required HtlcSwap? updatedSwap,
  }) async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      throw StateError('Cannot store an HTLC checkpoint without a chain id');
    }
    if (updatedSwap != null && updatedSwap.chainId != chainId) {
      throw StateError(
        'Cannot store an HTLC swap update for a different chain',
      );
    }

    await _dataProvider.writeProcessedHtlcBlock(
      chainId: chainId,
      height: height,
      updatedEntry: updatedSwap == null ? null : _encodeSwap(updatedSwap),
      maximumStoredSwaps: kMaxP2pSwapsToStore,
      prunableStates: <String>[
        P2pSwapState.completed.name,
        P2pSwapState.unsuccessful.name,
      ],
    );
  }

  @override
  Future<void> deleteSwap(String swapId) =>
      _dataProvider.deleteSwapEntry(swapId);

  @override
  Future<void> deleteInactiveSwaps() async {
    final int? chainId = _chainIdProvider();
    if (chainId == null) {
      return;
    }

    await _dataProvider.deleteSwapEntriesByState(chainId, <String>[
      P2pSwapState.completed.name,
      P2pSwapState.unsuccessful.name,
      P2pSwapState.error.name,
    ]);
  }

  HtlcSwapEntry _encodeSwap(HtlcSwap swap) => HtlcSwapEntry(
    id: swap.id,
    chainId: swap.chainId,
    state: swap.state.name,
    direction: swap.direction.name,
    hashLock: swap.hashLock,
    initialHtlcId: swap.initialHtlcId,
    counterHtlcId: swap.counterHtlcId,
    startTime: swap.startTime,
    payloadJson: jsonEncode(swap.toJson()),
  );

  HtlcSwap? _decodeNullableSwap(HtlcSwapEntry? entry) =>
      entry == null ? null : _decodeSwap(entry);

  HtlcSwap _decodeSwap(HtlcSwapEntry entry) {
    return P2pSwap.fromJson(
          jsonDecode(entry.payloadJson) as Map<String, dynamic>,
        )
        as HtlcSwap;
  }
}
