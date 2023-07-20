import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DelegateButtonBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> delegateToPillar(
    String? pillarName,
  ) async {
    try {
      addEvent(null);
      AccountBlockTemplate transactionParams = zenon!.embedded.pillar.delegate(
        pillarName!,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'delegate to Pillar',
        waitForRequiredPlasma: true,
      ).then(
        (response) async {
          await Future.delayed(kDelayAfterAccountBlockCreationCall);
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
