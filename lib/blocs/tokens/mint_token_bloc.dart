import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MintTokenBloc extends BaseBloc<AccountBlockTemplate> {
  void mintToken(
    Token token,
    String amount,
    Address beneficiaryAddress,
  ) {
    try {
      AccountBlockTemplate transactionParams = zenon!.embedded.token.mintToken(
        token.tokenStandard,
        amount.toNum().extractDecimals(token.decimals),
        beneficiaryAddress,
      );
      AccountBlockUtils.createAccountBlock(transactionParams, 'mint token',
              waitForRequiredPlasma: true)
          .then(
        (response) {
          response.amount = amount.toNum().extractDecimals(token.decimals);
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
