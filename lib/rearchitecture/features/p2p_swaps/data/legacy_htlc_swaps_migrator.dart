import 'dart:convert';
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Summarizes the outcome of migrating legacy Hive HTLC swaps into Drift.
class LegacyHtlcSwapsMigrationResult {
  /// Creates a migration summary.
  const LegacyHtlcSwapsMigrationResult({
    required this.migratedCount,
    required this.failedCount,
    required this.deletedLegacyBoxes,
  });

  /// Number of valid legacy swaps submitted to Drift via `insertOrIgnore`
  /// (existing swap ids in Drift are preserved without overwrite).
  final int migratedCount;

  /// Number of legacy entries that failed to decode or could not be migrated.
  final int failedCount;

  /// Whether all detected legacy Hive boxes were cleanly removed from disk.
  final bool deletedLegacyBoxes;
}

/// Performs a one-time, idempotent migration of legacy Hive-encrypted HTLC
/// swaps (`htlc_swaps_box_<baseAddress>`) into the Drift-backed repository.
class LegacyHtlcSwapsMigrator {
  /// Creates a migrator writing legacy swaps into the given repository.
  LegacyHtlcSwapsMigrator({
    required this._swapRepository,
    HiveInterface? hive,
    this._hiveDirectoryPath,
    Logger? logger,
  }) : _hive = hive ?? Hive,
       _logger = logger ?? Logger('LegacyHtlcSwapsMigrator');

  final HtlcSwapRepository _swapRepository;
  final HiveInterface _hive;
  final String? _hiveDirectoryPath;
  final Logger _logger;

  /// Migrates any legacy Hive HTLC swaps for [walletBaseAddress] using
  /// [encryptionKey], removes migrated keys from the legacy Hive box, and
  /// deletes the obsolete legacy Hive boxes once all entries are durably
  /// stored in Drift.
  ///
  /// Errors are logged by type/code only (never logging raw payloads, SQL
  /// parameters, secret preimages, or encryption keys) and never throw out of
  /// wallet unlock.
  Future<LegacyHtlcSwapsMigrationResult> migrateIfNeeded({
    required String walletBaseAddress,
    required List<int> encryptionKey,
  }) async {
    int migratedCount = 0;
    int failedCount = 0;
    bool swapsBoxCleaned = true;

    final String trimmedAddress = walletBaseAddress.trim();
    if (trimmedAddress.isNotEmpty) {
      final String swapsBoxName = '${kHtlcSwapsBox}_$trimmedAddress';
      Box<dynamic>? swapsBox;
      bool openedByMigrator = false;

      try {
        final bool hasSwapsBox = await _boxExistsOrIsOpen(swapsBoxName);
        if (hasSwapsBox) {
          if (_hive.isBoxOpen(swapsBoxName)) {
            swapsBox = _hive.box<dynamic>(swapsBoxName);
          } else {
            swapsBox = await _hive.openBox<dynamic>(
              swapsBoxName,
              encryptionCipher: HiveAesCipher(encryptionKey),
              path: _hiveDirectoryPath,
            );
            openedByMigrator = true;
          }

          final List<HtlcSwap> validSwaps = <HtlcSwap>[];
          final List<dynamic> validKeys = <dynamic>[];
          for (final MapEntry<dynamic, dynamic> entry
              in swapsBox.toMap().entries) {
            final HtlcSwap? swap = _decodeLegacySwap(
              entryKey: entry.key,
              rawValue: entry.value,
            );
            if (swap != null) {
              validSwaps.add(swap);
              validKeys.add(entry.key);
            } else {
              failedCount++;
            }
          }

          if (validSwaps.isNotEmpty) {
            await _swapRepository.storeMissingSwaps(validSwaps);
            migratedCount = validSwaps.length;

            // Remove migrated keys immediately so a retained box (from a
            // corrupt sibling entry or failed deleteFromDisk) cannot resurrect
            // swaps the user later deletes from Drift.
            try {
              await swapsBox.deleteAll(validKeys);
            } on Object catch (error) {
              _logger.warning(
                'Failed removing migrated keys from legacy Hive HTLC swaps '
                'box $swapsBoxName: ${_safeErrorSummary(error)}',
              );
            }
          }

          if (failedCount == 0) {
            try {
              await swapsBox.deleteFromDisk();
            } on Object catch (error) {
              swapsBoxCleaned = false;
              _logger.warning(
                'Failed deleting migrated legacy Hive HTLC swaps box '
                '$swapsBoxName: ${_safeErrorSummary(error)}',
              );
            }
          } else {
            swapsBoxCleaned = false;
          }
        }
      } on Object catch (error) {
        failedCount++;
        swapsBoxCleaned = false;
        _logger.warning(
          'Failed migrating legacy Hive HTLC swaps box $swapsBoxName: '
          '${_safeErrorSummary(error)}',
        );
      } finally {
        if (openedByMigrator && swapsBox != null && swapsBox.isOpen) {
          try {
            await swapsBox.close();
          } on Object catch (error) {
            _logger.warning(
              'Failed closing legacy Hive HTLC swaps box $swapsBoxName: '
              '${_safeErrorSummary(error)}',
            );
          }
        }
      }
    }

    // Legacy last_checked_htlc_block_box stored a single chain-agnostic height.
    // Leaving Drift's per-chain HtlcScanCheckpoints at 0 causes
    // HtlcSwapSyncService to rescan safely from oldestSwapStartTime per chain,
    // avoiding cross-chain checkpoint corruption. Delete the obsolete Hive box
    // once the swaps box is clean (or absent) so it does not linger past a
    // wallet password change.
    bool checkpointBoxCleaned = true;
    if (swapsBoxCleaned) {
      checkpointBoxCleaned = await _deleteBoxIfPresent(
        kLastCheckedHtlcBlockBox,
      );
    }

    return LegacyHtlcSwapsMigrationResult(
      migratedCount: migratedCount,
      failedCount: failedCount,
      deletedLegacyBoxes: swapsBoxCleaned && checkpointBoxCleaned,
    );
  }

  /// Removes all legacy `htlc_swaps_box_*` files from disk during a full
  /// wallet reset (including resets initiated from the lock screen before
  /// addresses are loaded).
  Future<void> deleteLegacyBoxesOnReset() async {
    const String legacyPrefix = '${kHtlcSwapsBox}_';
    try {
      final Directory cacheDir = Directory(
        _hiveDirectoryPath ?? znnDefaultPaths.cache.path,
      );
      if (!cacheDir.existsSync()) {
        return;
      }
      for (final FileSystemEntity entity in cacheDir.listSync()) {
        if (entity is! File) {
          continue;
        }
        final String fileName = path.basename(entity.path).toLowerCase();
        final bool isLegacySwapFile =
            fileName.startsWith(legacyPrefix) &&
            (fileName.endsWith('.hive') ||
                fileName.endsWith('.hivec') ||
                fileName.endsWith('.lock'));
        if (!isLegacySwapFile) {
          continue;
        }
        try {
          await entity.delete();
        } on Object catch (error) {
          _logger.warning(
            'Failed deleting legacy Hive swap file $fileName: '
            '${_safeErrorSummary(error)}',
          );
        }
      }
    } on Object catch (error) {
      _logger.warning(
        'Failed scanning cache directory for legacy Hive swap boxes: '
        '${_safeErrorSummary(error)}',
      );
    }
  }

  HtlcSwap? _decodeLegacySwap({
    required dynamic entryKey,
    required dynamic rawValue,
  }) {
    if (rawValue is! String) {
      _logger.warning(
        'Skipping non-string legacy HTLC swap entry for key $entryKey '
        '(${rawValue.runtimeType})',
      );
      return null;
    }

    try {
      final Object? decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        _logger.warning(
          'Skipping legacy HTLC swap entry for key $entryKey: '
          'decoded value is not a JSON object',
        );
        return null;
      }

      final P2pSwap swap = P2pSwap.fromJson(decoded);
      if (swap is! HtlcSwap) {
        _logger.warning(
          'Skipping legacy P2P swap entry for key $entryKey: '
          'unsupported swap type ${swap.runtimeType}',
        );
        return null;
      }
      return swap;
    } on Object catch (error) {
      // Do not log rawValue or exception details that might echo secret
      // preimages.
      _logger.warning(
        'Skipping unreadable legacy HTLC swap entry for key $entryKey: '
        '${_safeErrorSummary(error)}',
      );
      return null;
    }
  }

  String _safeErrorSummary(Object error) => formatSafeSwapErrorSummary(error);

  Future<bool> _boxExistsOrIsOpen(String boxName) {
    if (_hive.isBoxOpen(boxName)) {
      return Future<bool>.value(true);
    }
    return _hive.boxExists(boxName, path: _hiveDirectoryPath);
  }

  Future<bool> _deleteBoxIfPresent(String boxName) async {
    try {
      if (_hive.isBoxOpen(boxName)) {
        await _hive.box<dynamic>(boxName).deleteFromDisk();
        return true;
      }
      if (await _hive.boxExists(boxName, path: _hiveDirectoryPath)) {
        await _hive.deleteBoxFromDisk(boxName, path: _hiveDirectoryPath);
      }
      return true;
    } on Object catch (error) {
      _logger.warning(
        'Failed deleting legacy Hive box $boxName: '
        '${_safeErrorSummary(error)}',
      );
      return false;
    }
  }
}
