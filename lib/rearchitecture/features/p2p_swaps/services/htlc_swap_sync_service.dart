import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenon_syrius_wallet_flutter/model/block_data.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/date_time_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const List<P2pSwapState> _kActiveStates = <P2pSwapState>[P2pSwapState.active];
const List<P2pSwapState> _kUnresolvedStates = <P2pSwapState>[
  P2pSwapState.pending,
  P2pSwapState.active,
  P2pSwapState.reclaimable,
];
const List<P2pSwapState> _kExpirableStates = <P2pSwapState>[
  P2pSwapState.pending,
  P2pSwapState.active,
];
const List<P2pSwapState> _kAutoUnlockableStates = <P2pSwapState>[
  P2pSwapState.active,
  P2pSwapState.reclaimable,
];

const Duration _kPollInterval = Duration(seconds: 5);

/// Synchronizes stored HTLC swaps with on-chain activity.
class HtlcSwapSyncService {
  /// Creates an HTLC swap synchronization service.
  HtlcSwapSyncService({
    required this._swapRepository,
    required this._autoUnlockService,
    required this._zenon,
  });

  final Logger _logger = Logger('HtlcSwapsHandler');

  final HtlcSwapRepository _swapRepository;
  final HtlcSwapAutoUnlockService _autoUnlockService;
  final Zenon _zenon;

  bool _isRunning = false;
  Timer? _timer;
  Future<void>? _currentRun;

  /// Starts periodic synchronization.
  void start() {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    _currentRun = _runPeriodically();
  }

  /// Stops periodic synchronization and waits for the current run to finish.
  Future<void> stop() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    await _currentRun;
    _currentRun = null;
  }

  /// Whether an active incoming swap is currently stored.
  Future<bool> hasActiveIncomingSwaps() async {
    try {
      final List<HtlcSwap> activeSwaps = await _swapRepository.getSwapsByState(
        _kActiveStates,
      );
      return activeSwaps.any(
        (HtlcSwap swap) => swap.direction == P2pSwapDirection.incoming,
      );
    } on Object catch (e) {
      _logger.warning(
        'hasActiveIncomingSwaps failed: ${formatSafeSwapErrorSummary(e)}',
      );
      return false;
    }
  }

  Future<void> _runPeriodically() async {
    try {
      await _enableWakelockIfNeeded();
      if (_zenon.wsClient.isClosed()) {
        return;
      }

      final List<HtlcSwap> unresolvedSwaps = await _swapRepository
          .getSwapsByState(_kUnresolvedStates);
      if (unresolvedSwaps.isNotEmpty) {
        await _processUnresolvedSwaps(unresolvedSwaps);
      }
    } on Object catch (e) {
      // Avoid logging raw storage exceptions (e.g. SqliteException /
      // DriftWrappedException / DriftRemoteException) whose string
      // representations can include SQL bind parameters containing secret HTLC
      // preimages.
      _logger.warning(
        '_runPeriodically failed: ${formatSafeSwapErrorSummary(e)}',
      );
    } finally {
      _scheduleNextRun();
    }
  }

  Future<void> _processUnresolvedSwaps(List<HtlcSwap> swaps) async {
    if (await _hasNewHtlcBlocks()) {
      final List<AccountBlock> newBlocks = await _getNewHtlcBlocks(swaps);
      await _processHtlcBlocks(newBlocks);
    }
    await _checkForExpiredSwaps();
    await _checkForAutoUnlockableSwaps();
  }

  void _scheduleNextRun() {
    if (!_isRunning) {
      return;
    }
    _timer = Timer(_kPollInterval, () {
      _currentRun = _runPeriodically();
    });
  }

  Future<void> _enableWakelockIfNeeded() async {
    if (await hasActiveIncomingSwaps()) {
      try {
        await WakelockPlus.enable();
      } on Object catch (e, stackTrace) {
        _logger.log(Level.WARNING, '_enableWakelockIfNeeded', e, stackTrace);
      }
    }
  }

  Future<int?> _getHtlcFrontierHeight() async {
    try {
      final AccountBlock? frontier = await _zenon.ledger
          .getFrontierAccountBlock(htlcAddress);
      return frontier?.height;
    } on Object catch (e, stackTrace) {
      _logger.log(Level.WARNING, '_getHtlcFrontierHeight', e, stackTrace);
    }
    return null;
  }

  Future<bool> _hasNewHtlcBlocks() async {
    final int? frontierHeight = await _getHtlcFrontierHeight();
    final int lastCheckedHeight = await _swapRepository
        .getLastCheckedHtlcBlockHeight();
    return frontierHeight != null && frontierHeight > lastCheckedHeight;
  }

  Future<List<AccountBlock>> _getNewHtlcBlocks(List<HtlcSwap> swaps) async {
    final int lastCheckedHeight = await _swapRepository
        .getLastCheckedHtlcBlockHeight();
    final int oldestSwapStartTime = _getOldestSwapStartTime(swaps) ?? 0;
    int lastCheckedBlockTime = 0;

    if (lastCheckedHeight > 0) {
      try {
        final int? blockTime =
            await AccountBlockUtils.getTimeForAccountBlockHeight(
              htlcAddress,
              lastCheckedHeight,
            );
        lastCheckedBlockTime = blockTime ?? 0;
      } on Object catch (e, stackTrace) {
        _logger.log(Level.WARNING, '_getNewHtlcBlocks', e, stackTrace);
        return <AccountBlock>[];
      }
    }

    try {
      return await AccountBlockUtils.getAccountBlocksAfterTime(
        htlcAddress,
        max(oldestSwapStartTime, lastCheckedBlockTime),
      );
    } on Object catch (e, stackTrace) {
      _logger.log(Level.WARNING, '_getNewHtlcBlocks', e, stackTrace);
      return <AccountBlock>[];
    }
  }

  Future<void> _processHtlcBlocks(List<AccountBlock> blocks) async {
    for (final AccountBlock block in blocks) {
      final HtlcSwap? updatedSwap = await _getSwapUpdateFromBlock(block);
      await _swapRepository.storeProcessedHtlcBlock(
        height: block.height,
        updatedSwap: updatedSwap,
      );
    }
  }

  Future<HtlcSwap?> _getSwapUpdateFromBlock(AccountBlock htlcBlock) async {
    if (htlcBlock.blockType != BlockTypeEnum.contractReceive.index) {
      return null;
    }

    final AccountBlock? pairedBlock = htlcBlock.pairedAccountBlock;
    if (pairedBlock == null) {
      return null;
    }

    final BlockData? blockData = AccountBlockUtils.getDecodedBlockData(
      Definitions.htlc,
      pairedBlock.data,
    );

    if (blockData == null) {
      return null;
    }

    final HtlcSwap? swap = await _tryGetSwapFromBlockData(blockData);
    if (swap == null) {
      return null;
    }

    if (swap.chainId != pairedBlock.chainIdentifier) {
      return null;
    }

    switch (blockData.function) {
      case 'Create':
        return _getCreateUpdate(pairedBlock, blockData, swap);
      case 'Unlock':
        return _getUnlockUpdate(
          blockData,
          swap,
          hasDescendantBlocks: htlcBlock.descendantBlocks.isNotEmpty,
        );
      case 'Reclaim':
        return _getReclaimUpdate(
          blockData,
          swap,
          hasDescendantBlocks: htlcBlock.descendantBlocks.isNotEmpty,
        );
    }
    return null;
  }

  HtlcSwap? _getCreateUpdate(
    AccountBlock pairedBlock,
    BlockData blockData,
    HtlcSwap swap,
  ) {
    if (swap.state == P2pSwapState.pending) {
      return swap.copyWith(state: P2pSwapState.active);
    }

    final String htlcId = pairedBlock.hash.toString();
    final bool isUntrackedCounterHtlc =
        swap.state == P2pSwapState.active &&
        htlcId != swap.initialHtlcId &&
        swap.counterHtlcId == null;
    if (!isUntrackedCounterHtlc ||
        !_isValidCounterHtlc(pairedBlock, blockData, swap)) {
      return null;
    }

    final int? expirationTime = _parseAbiInt(
      blockData.params['expirationTime'],
    );
    if (expirationTime == null) {
      return null;
    }
    return swap.copyWith(
      counterHtlcId: htlcId,
      toAmount: pairedBlock.amount,
      toToken: pairedBlock.token,
      counterHtlcExpirationTime: expirationTime,
    );
  }

  HtlcSwap? _getUnlockUpdate(
    BlockData blockData,
    HtlcSwap swap, {
    required bool hasDescendantBlocks,
  }) {
    if (!hasDescendantBlocks) {
      return null;
    }

    HtlcSwap updatedSwap = swap;
    bool preimageWasAdded = false;
    if (swap.preimage == null) {
      if (!blockData.params.containsKey('preimage')) {
        return null;
      }
      final String preimage = FormatUtils.encodeHexString(
        blockData.params['preimage'],
      );
      updatedSwap = swap.copyWith(preimage: preimage);
      preimageWasAdded = true;
    }

    final String htlcId = blockData.params['id'].toString();
    final bool completesIncomingSwap =
        updatedSwap.direction == P2pSwapDirection.incoming &&
        htlcId == updatedSwap.initialHtlcId;
    final bool completesOutgoingSwap =
        updatedSwap.direction == P2pSwapDirection.outgoing &&
        updatedSwap.state == P2pSwapState.active &&
        htlcId == updatedSwap.counterHtlcId;
    if (completesIncomingSwap || completesOutgoingSwap) {
      return updatedSwap.copyWith(state: P2pSwapState.completed);
    }

    return preimageWasAdded ? updatedSwap : null;
  }

  HtlcSwap? _getReclaimUpdate(
    BlockData blockData,
    HtlcSwap swap, {
    required bool hasDescendantBlocks,
  }) {
    if (!hasDescendantBlocks) {
      return null;
    }

    final String htlcId = blockData.params['id'].toString();
    final bool reclaimsOutgoingSwap =
        swap.direction == P2pSwapDirection.outgoing &&
        htlcId == swap.initialHtlcId;
    final bool reclaimsIncomingSwap =
        swap.direction == P2pSwapDirection.incoming &&
        htlcId == swap.counterHtlcId;
    if (!reclaimsOutgoingSwap && !reclaimsIncomingSwap) {
      return null;
    }

    return swap.copyWith(state: P2pSwapState.unsuccessful);
  }

  Future<HtlcSwap?> _tryGetSwapFromBlockData(BlockData data) async {
    HtlcSwap? swap;
    if (data.params.containsKey('id')) {
      swap = await _swapRepository.getSwapByHtlcId(
        data.params['id'].toString(),
      );
    }
    if (data.params.containsKey('hashLock') && swap == null) {
      swap = await _swapRepository.getSwapByHashLock(
        Hash.fromBytes(data.params['hashLock']).toString(),
      );
    }
    return swap;
  }

  bool _isValidCounterHtlc(AccountBlock block, BlockData data, HtlcSwap swap) {
    // Verify that the recipient is the initiator's address
    if (!data.params.containsKey('hashLocked') ||
        data.params['hashLocked'] != Address.parse(swap.selfAddress)) {
      return false;
    }

    // Verify that the creator is the counterparty.
    if (block.address != Address.parse(swap.counterpartyAddress)) {
      return false;
    }

    // Verify that the hash types match.
    if (!data.params.containsKey('hashType') ||
        _parseAbiInt(data.params['hashType']) != swap.hashType) {
      return false;
    }

    // Verify that block data contains a valid expiration time parameter.
    if (!data.params.containsKey('expirationTime') ||
        _parseAbiInt(data.params['expirationTime']) == null) {
      return false;
    }

    return true;
  }

  int? _parseAbiInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is BigInt && value.isValidInt) {
      return value.toInt();
    }
    return null;
  }

  Future<void> _checkForExpiredSwaps() async {
    final List<HtlcSwap> swaps = await _swapRepository.getSwapsByState(
      _kExpirableStates,
    );
    final int now = DateTime.now().unixTimestamp;
    for (final HtlcSwap swap in swaps) {
      if (!_isExpired(swap, now)) {
        continue;
      }
      await _swapRepository.storeSwap(
        swap.copyWith(state: P2pSwapState.reclaimable),
      );
    }
  }

  bool _isExpired(HtlcSwap swap, int now) {
    if (swap.initialHtlcExpirationTime < now) {
      return true;
    }

    final int? counterExpirationTime = swap.counterHtlcExpirationTime;
    return counterExpirationTime != null &&
        counterExpirationTime - kMinSafeTimeToCompleteSwap.inSeconds < now;
  }

  Future<void> _checkForAutoUnlockableSwaps() async {
    // It is important to check swaps that are in reclaimable state as well,
    // since the counterparty may have published the preimage at the last moment
    // before the HTLC would have expired. In this situation the swap's state
    // may have already been changed to reclaimable.
    final List<HtlcSwap> swaps = await _swapRepository.getSwapsByState(
      _kAutoUnlockableStates,
    );
    await _autoUnlockService.unlockNext(
      swaps.where(
        (HtlcSwap swap) =>
            swap.direction == P2pSwapDirection.incoming &&
            swap.preimage != null,
      ),
    );
  }

  int? _getOldestSwapStartTime(List<HtlcSwap> swaps) {
    if (swaps.isEmpty) {
      return null;
    }
    return swaps.map((HtlcSwap swap) => swap.startTime).reduce(min);
  }
}
