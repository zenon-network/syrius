import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PlasmaOptionsBloc extends BaseBloc<AccountBlockTemplate?> {
  void generatePlasma(String beneficiaryAddress, BigInt amount) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.plasma.fuse(
        Address.parse(beneficiaryAddress),
        amount,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'fuse ${kQsrCoin.symbol} for Plasma',
        waitForRequiredPlasma: true,
      ).then(
        (response) {
          ZenonAddressUtils.refreshBalance();
          addEvent(response);
        },
      ).onError(
        (error, stackTrace) {
          addError(error, stackTrace);
        },
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
