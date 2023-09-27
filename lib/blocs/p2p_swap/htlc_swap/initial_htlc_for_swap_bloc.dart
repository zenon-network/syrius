import 'dart:async';

import 'package:collection/collection.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class InitialHtlcForSwapBloc extends BaseBloc<HtlcInfo?> {
  final _minimumRequiredDuration =
      kMinSafeTimeToFindPreimage + kCounterHtlcDuration;
  Future<void> getInitialHtlc(Hash id) async {
    try {
      final htlc = await zenon!.embedded.htlc.getById(id);
      final hashlock = FormatUtils.encodeHexString(htlc.hashLock);
      if (!kDefaultAddressList.contains(htlc.hashLocked.toString())) {
        throw 'This deposit is not intended for you.';
      }
      if (kDefaultAddressList.contains(htlc.timeLocked.toString())) {
        throw 'Cannot join a swap that you have started.';
      }
      if (htlcSwapsService!.getSwapByHtlcId(htlc.id.toString()) != null) {
        throw 'This deposit is already used in another swap.';
      }
      if (htlcSwapsService!.getSwapByHashLock(hashlock) != null) {
        throw 'The deposit\'s hashlock is already used in another swap.';
      }
      final remainingDuration =
          Duration(seconds: htlc.expirationTime - DateTimeUtils.unixTimeNow);
      if (remainingDuration < _minimumRequiredDuration) {
        if (remainingDuration.inSeconds <= 0) {
          throw 'This deposit has expired.';
        }
        throw 'This deposit will expire too soon for a safe swap.';
      }
      if (remainingDuration > kMaxAllowedInitialHtlcDuration) {
        throw 'The deposit\'s duration is too long. Expected ${kMaxAllowedInitialHtlcDuration.inHours} hours at most.';
      }
      final creationBlock = await zenon!.ledger.getAccountBlockByHash(htlc.id);
      if (htlc.expirationTime -
              creationBlock!.confirmationDetail!.momentumTimestamp >
          kMaxAllowedInitialHtlcDuration.inSeconds) {
        throw 'The deposit was created too long ago.';
      }

      // Verify that the hashlock has not been used in another currently active
      // HTLC.
      final htlcBlocks = await AccountBlockUtils.getAccountBlocksAfterTime(
          htlcAddress,
          htlc.expirationTime - kMaxAllowedInitialHtlcDuration.inSeconds);
      if (htlcBlocks.firstWhereOrNull((block) =>
              !_isInitialHtlcBlock(block, htlc.id) &&
              _hasMatchingHashlock(block, hashlock)) !=
          null) {
        throw 'The hashlock is not unique.';
      }
      addEvent(htlc);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}

bool _isInitialHtlcBlock(AccountBlock block, Hash initialHtlcId) {
  if (block.blockType != BlockTypeEnum.contractReceive.index) {
    return false;
  }
  return block.pairedAccountBlock!.hash == initialHtlcId;
}

bool _hasMatchingHashlock(AccountBlock block, String hashlock) {
  if (block.blockType != BlockTypeEnum.contractReceive.index) {
    return false;
  }

  final blockData = AccountBlockUtils.getDecodedBlockData(
      Definitions.htlc, block.pairedAccountBlock!.data);

  if (blockData == null || blockData.function != 'Create') {
    return false;
  }

  if (!blockData.params.containsKey('hashLock')) {
    return false;
  }

  return FormatUtils.encodeHexString(blockData.params['hashLock']) == hashlock;
}
