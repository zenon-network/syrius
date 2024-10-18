import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class VoteProjectBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> voteProject(Hash id, AcceleratorProjectVote vote) async {
    try {
      addEvent(null);
      final pillarInfo = (await zenon!.embedded.pillar.getByOwner(
        Address.parse(kSelectedAddress!),
      ))
          .first;
      final transactionParams =
          zenon!.embedded.accelerator.voteByName(
        id,
        pillarInfo.name,
        vote.index,
      );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'vote for project',
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
