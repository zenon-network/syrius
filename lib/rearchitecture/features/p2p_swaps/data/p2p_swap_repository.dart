import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';

/// Defines persistent storage operations for peer-to-peer swaps.
abstract class P2pSwapRepository<T extends P2pSwap> {
  /// Returns all stored swaps.
  Future<List<T>> getAllSwaps();

  /// Emits all stored swaps whenever they change.
  Stream<List<T>> watchAllSwaps();

  /// Returns swaps whose state is included in [states].
  Future<List<T>> getSwapsByState(List<P2pSwapState> states);

  /// Returns the swap identified by [id], if one exists.
  Future<T?> getSwapById(String id);

  /// Stores or updates [swap].
  Future<void> storeSwap(T swap);

  /// Deletes the swap identified by [swapId].
  Future<void> deleteSwap(String swapId);

  /// Deletes stored swaps that are no longer active.
  Future<void> deleteInactiveSwaps();
}
