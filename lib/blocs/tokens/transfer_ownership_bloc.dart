import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TransferOwnershipBloc extends BaseBloc<AccountBlockTemplate> {
  void transferOwnership(
    TokenStandard tokenStandard,
    Address owner,
    bool isMintable,
    bool isBurnable,
  ) {
    try {
      final transactionParams =
          zenon!.embedded.token.updateToken(
        tokenStandard,
        owner,
        isMintable,
        isBurnable,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'transfer token',
        waitForRequiredPlasma: true,
      )
          .then(
        addEvent,
      )
          .onError(
        addError,
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
