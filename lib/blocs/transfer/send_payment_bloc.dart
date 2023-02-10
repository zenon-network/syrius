import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SendPaymentBloc extends BaseBloc<AccountBlockTemplate?> {
  void sendTransfer({
    required String? fromAddress,
    required String toAddress,
    required String amount,
    required List<int>? data,
    required Token token,
  }) {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = AccountBlockTemplate.send(
        Address.parse(toAddress),
        token.tokenStandard,
        amount.toNum().extractDecimals(token.decimals),
        data,
      );
      KeyPair blockSigningKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(fromAddress),
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'send transaction',
        blockSigningKey: blockSigningKeyPair,
        waitForRequiredPlasma: true,
      ).then(
        (response) {
          AddressUtils.refreshBalance();
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
