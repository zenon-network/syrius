import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/syrius_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/date_time_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Validates and unlocks HTLC swaps on-chain.
class HtlcSwapUnlockService {
  /// Creates an HTLC swap unlock service.
  HtlcSwapUnlockService({
    required this._accountBlockUtils,
    required this._zenon,
    int Function()? unixTimeProvider,
  }) : _unixTimeProvider = unixTimeProvider ?? _currentUnixTime;

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final int Function() _unixTimeProvider;

  static int _currentUnixTime() => DateTime.now().unixTimestamp;

  /// Validates [swap] and submits its HTLC unlock transaction.
  Future<AccountBlockTemplate> unlock(HtlcSwap swap) async {
    final String? htlcIdString = switch (swap.direction) {
      P2pSwapDirection.outgoing => swap.counterHtlcId,
      P2pSwapDirection.incoming => swap.initialHtlcId,
    };
    final String? encodedPreimage = swap.preimage;
    if (htlcIdString == null || encodedPreimage == null) {
      throw SyriusException('Invalid swap');
    }

    final Hash htlcId = Hash.parse(htlcIdString);
    final HtlcInfo htlc = await _zenon.embedded.htlc.getById(htlcId);
    if (FormatUtils.encodeHexString(htlc.hashLock) != swap.hashLock ||
        htlc.hashLocked.toString() != swap.selfAddress) {
      throw SyriusException('Invalid swap');
    }
    if (!kDefaultAddressList.contains(htlc.hashLocked.toString())) {
      throw SyriusException(
        'Swap address not in default addresses. Please add the address '
        'in the addresses list.',
      );
    }
    if (htlc.expirationTime <=
        _unixTimeProvider() + kMinSafeTimeToCompleteSwap.inSeconds) {
      throw SyriusException('The swap will expire too soon for a safe swap.');
    }

    final List<int> preimage;
    try {
      preimage = FormatUtils.decodeHexString(encodedPreimage);
    } on FormatException {
      throw SyriusException('Invalid swap secret.');
    }
    if (htlc.keyMaxSize < preimage.length) {
      throw SyriusException(
        'The swap secret size exceeds the maximum allowed size.',
      );
    }

    final AccountBlockTemplate transactionParams = _zenon.embedded.htlc.unlock(
      htlc.id,
      preimage,
    );
    return await _accountBlockUtils.createAccountBlock(
      transactionParams,
      'complete swap',
      address: htlc.hashLocked,
      waitForRequiredPlasma: true,
    );
  }
}
