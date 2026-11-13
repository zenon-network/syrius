import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/accelerator_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class VoteProjectBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> voteProject(Hash id, AcceleratorProjectVote vote) async {
    try {
      addEvent(null);
      final address = Address.parse(kSelectedAddress!);
      final byOwner = await zenon!.embedded.pillar.getByOwner(address);
      final PillarInfo? pillarInfo = byOwner.isNotEmpty
          ? byOwner.first
          : AcceleratorUtils.pillarForAddress(
              (await zenon!.embedded.pillar.getAll()).list, address);
      if (pillarInfo == null) {
        addError('This address owns or produces no pillar', StackTrace.current);
        return;
      }
      AccountBlockTemplate transactionParams =
          AcceleratorUtils.voteMethodFor(pillarInfo, address) ==
                  AcceleratorVoteMethod.byName
              ? zenon!.embedded.accelerator.voteByName(
                  id,
                  pillarInfo.name,
                  vote.index,
                )
              : zenon!.embedded.accelerator.voteByProdAddress(
                  id,
                  vote.index,
                );
      AccountBlockUtils.createAccountBlock(
        transactionParams,
        'vote for project',
      )
          .then(
        (block) => addEvent(block),
      )
          .onError(
        (error, stackTrace) {
          addError(error, stackTrace);
        },
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
