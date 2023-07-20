import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SubmitDonationBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> submitDonation(BigInt znnAmount, BigInt qsrAmount) async {
    try {
      addEvent(null);
      if (znnAmount > BigInt.zero) {
        await _sendDonationBlock(zenon!.embedded.accelerator.donate(
          znnAmount,
          kZnnCoin.tokenStandard,
        ));
      }
      if (qsrAmount > BigInt.zero) {
        await _sendDonationBlock(zenon!.embedded.accelerator.donate(
          qsrAmount,
          kQsrCoin.tokenStandard,
        ));
      }
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  Future<void> _sendDonationBlock(
      AccountBlockTemplate transactionParams) async {
    await AccountBlockUtils.createAccountBlock(
      transactionParams,
      'donate for accelerator',
    ).then(
      (block) {
        sl.get<AcceleratorBalanceBloc>().getAcceleratorBalance();
        addEvent(block);
      },
    ).onError(
      (error, stackTrace) {
        addError(error, stackTrace);
      },
    );
  }
}
