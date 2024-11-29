import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class BurnTokenBloc extends BaseBloc<AccountBlockTemplate> {
  void burnToken(
    Token token,
    BigInt amount,
  ) {
    try {
      final AccountBlockTemplate transactionParams = zenon!.embedded.token.burnToken(
        token.tokenStandard,
        amount,
      );
      AccountBlockUtils().createAccountBlock(transactionParams, 'burn token',
              waitForRequiredPlasma: true,)
          .then(
        (AccountBlockTemplate response) {
          ZenonAddressUtils().refreshBalance();
          addEvent(response);
        },
      ).onError(
        addError,
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
