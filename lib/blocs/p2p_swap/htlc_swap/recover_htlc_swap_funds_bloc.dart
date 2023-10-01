import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/htlc_swap/reclaim_htlc_swap_funds_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class RecoverHtlcSwapFundsBloc extends ReclaimHtlcSwapFundsBloc {
  void recoverFunds({required Hash htlcId}) async {
    try {
      final htlc = await zenon!.embedded.htlc.getById(htlcId);

      if (!kDefaultAddressList.contains(htlc.timeLocked.toString())) {
        throw 'The deposit does not belong to you.';
      }

      if (htlc.expirationTime - DateTimeUtils.unixTimeNow > 0) {
        throw 'The deposit is locked until ${FormatUtils.formatDate(htlc.expirationTime * 1000, dateFormat: kDefaultDateTimeFormat)}.';
      }

      reclaimFunds(htlcId: htlcId, selfAddress: htlc.timeLocked);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
