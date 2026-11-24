import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_sync_status/services/node_sync_monitor.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_unlock_service.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/syrius_exception.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const Duration _kRetryCooldown = Duration(minutes: 2);

/// Unlocks eligible HTLC swaps one at a time.
class HtlcSwapAutoUnlockService {
  /// Creates an automatic HTLC swap unlock service.
  HtlcSwapAutoUnlockService({
    required this._notificationsBloc,
    required this._syncMonitor,
    required this._unlockService,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Logger _logger = Logger('HtlcSwapAutoUnlockService');
  final NodeSyncMonitor _syncMonitor;
  final DateTime Function() _now;
  final Map<String, DateTime> _recentAttempts = <String, DateTime>{};
  final NotificationsBloc _notificationsBloc;
  final HtlcSwapUnlockService _unlockService;

  bool _isUnlocking = false;

  /// Whether an unlock attempt is currently in progress.
  bool get isUnlocking => _isUnlocking;

  /// Attempts to unlock the next eligible swap in [candidates].
  Future<void> unlockNext(Iterable<HtlcSwap> candidates) async {
    final bool walletIsAvailable = kWalletFile != null;

    if (_isUnlocking || !walletIsAvailable) {
      return;
    }

    final DateTime now = _now();
    _recentAttempts.removeWhere(
      (_, DateTime attemptedAt) =>
          now.difference(attemptedAt) >= _kRetryCooldown,
    );

    HtlcSwap? swap;
    for (final HtlcSwap candidate in candidates) {
      if (!_recentAttempts.containsKey(candidate.initialHtlcId)) {
        swap = candidate;
        break;
      }
    }
    if (swap == null) {
      return;
    }

    _isUnlocking = true;
    try {
      if (!await _syncMonitor.isNodeSynced()) {
        return;
      }

      _recentAttempts[swap.initialHtlcId] = now;
      await _unlock(swap);
    } finally {
      _isUnlocking = false;
    }
  }

  Future<void> _unlock(HtlcSwap swap) async {
    try {
      final AccountBlockTemplate response = await _unlockService.unlock(swap);
      await _sendSuccessNotification(response, swap.selfAddress);
    } on SyriusException catch (error, stackTrace) {
      _logger.log(Level.WARNING, 'unlockNext', error, stackTrace);
      await _sendErrorNotification(error.toString());
    } on RpcException catch (error, stackTrace) {
      final RedactedSwapError sanitizedError = sanitizeSwapErrorForLogging(
        error,
      );
      _logger.log(Level.WARNING, 'unlockNext', sanitizedError, stackTrace);
      if (!error.message.contains('data non existent')) {
        await _sendErrorNotification(sanitizedError.summary);
      }
    } on Object catch (error, stackTrace) {
      final RedactedSwapError sanitizedError = sanitizeSwapErrorForLogging(
        error,
      );
      _logger.log(Level.WARNING, 'unlockNext', sanitizedError, stackTrace);
      await _sendErrorNotification(sanitizedError.summary);
    }
  }

  Future<void> _sendErrorNotification(String errorText) => _notify(
    WalletNotification(
      title: 'Failed to complete swap',
      timestamp: _now().millisecondsSinceEpoch,
      details: 'Failed to complete the swap: $errorText',
      type: NotificationType.error,
    ),
  );

  Future<void> _sendSuccessNotification(
    AccountBlockTemplate block,
    String toAddress,
  ) => _notify(
    WalletNotification(
      title: 'Transaction received on ${ZenonAddressUtils.getLabel(toAddress)}',
      timestamp: _now().millisecondsSinceEpoch,
      details: 'Transaction hash: ${block.hash}',
      type: NotificationType.paymentReceived,
    ),
  );

  Future<void> _notify(WalletNotification notification) async {
    try {
      await _notificationsBloc.addNotification(notification);
    } on Object catch (error, stackTrace) {
      _logger.log(Level.WARNING, 'notify', error, stackTrace);
    }
  }
}
