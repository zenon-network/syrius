import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class BurnTokenBloc extends BaseBloc<AccountBlockTemplate> {
  void burnToken(
    Token token,
    String amount,
  ) {
    try {
      AccountBlockTemplate transactionParams = zenon!.embedded.token.burnToken(
        token.tokenStandard,
        amount.toNum().extractDecimals(token.decimals),
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'burn token',
              waitForRequiredPlasma: true)
          .then(
        (response) {
          AddressUtils.refreshBalance();
          addEvent(response);
        },
      ).onError(
        (error, stackTrace) {
          addError(error.toString());
        },
      );
    } catch (e) {
      addError(e);
    }
  }
}
