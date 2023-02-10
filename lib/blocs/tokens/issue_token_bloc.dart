import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class IssueTokenBloc extends BaseBloc<AccountBlockTemplate> {
  void issueToken(NewTokenData tokenStepperData) {
    try {
      AccountBlockTemplate transactionParams = zenon!.embedded.token.issueToken(
          tokenStepperData.tokenName,
          tokenStepperData.tokenSymbol,
          tokenStepperData.tokenDomain,
          tokenStepperData.totalSupply
              .extractDecimals(tokenStepperData.decimals),
          tokenStepperData.maxSupply.extractDecimals(tokenStepperData.decimals),
          tokenStepperData.decimals,
          tokenStepperData.isMintable!,
          tokenStepperData.isOwnerBurnOnly!,
          tokenStepperData.isUtility!);
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'issue token',
        waitForRequiredPlasma: true,
      ).then(
        (response) {
          Hive.box(kFavoriteTokensBox).add(response.tokenStandard.toString());
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
