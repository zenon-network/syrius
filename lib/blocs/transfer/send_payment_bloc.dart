import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SendPaymentBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> sendTransfer({
    // TODO: make this argument non-nullable
    String? fromAddress,
    String? toAddress,
    BigInt? amount,
    List<int>? data,
    Token? token,
    AccountBlockTemplate? block,
  }) async {
    assert(
      block == null &&
              fromAddress != null &&
              toAddress != null &&
              amount != null &&
              token != null ||
          block != null && fromAddress != null,
    );
    try {
      addEvent(null);
      final accountBlock = block ??
          AccountBlockTemplate.send(
            Address.parse(toAddress!),
            token!.tokenStandard,
            amount!,
            data,
          );
      AccountBlockUtils.createAccountBlock(
        accountBlock,
        'send transaction',
        address: Address.parse(fromAddress!),
        waitForRequiredPlasma: true,
      ).then(
        (response) {
          ZenonAddressUtils.refreshBalance();
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
