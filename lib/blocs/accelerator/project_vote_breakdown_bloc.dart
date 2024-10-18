import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/pair.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ProjectVoteBreakdownBloc
    extends BaseBloc<Pair<VoteBreakdown, List<PillarVote?>?>?> {
  Future<void> getVoteBreakdown(String? pillarName, Hash projectId) async {
    try {
      addEvent(null);
      final voteBreakdown =
          await zenon!.embedded.accelerator.getVoteBreakdown(
        projectId,
      );
      List<PillarVote?>? pillarVoteList;
      if (pillarName != null) {
        pillarVoteList = await zenon!.embedded.accelerator.getPillarVotes(
          pillarName,
          [
            projectId.toString(),
          ],
        );
      }
      addEvent(Pair(voteBreakdown, pillarVoteList));
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
