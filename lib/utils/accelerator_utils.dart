import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// How an address is authorised to cast a pillar vote on a votable hash.
enum AcceleratorVoteMethod {
  /// VoteByName — only the pillar's owner (stake) address may send it.
  byName,

  /// VoteByProdAddress — only the pillar's block-producing address may
  /// send it. On-chain the vote is recorded under the pillar's name,
  /// same as VoteByName.
  byProdAddress,
}

class AcceleratorUtils {
  AcceleratorUtils._();

  /// Resolves the pillar that the currently selected address owns or
  /// produces, or null when the address has no pillar role. A single
  /// getAll RPC covers both cases (the node implements getByOwner as
  /// getAll plus a filter); shared by the Accelerator tab and the
  /// vote bloc so both keep the same owner-then-producer precedence.
  static Future<PillarInfo?> selectedAddressPillar() async {
    final address = Address.parse(kSelectedAddress!);
    final all = await zenon!.embedded.pillar.getAll();
    return pillarForAddress(all.list, address);
  }

  /// Returns the pillar that [address] owns or produces, or null when
  /// the address has no pillar role. An owner match wins over a
  /// producer match when an address is somehow both.
  static PillarInfo? pillarForAddress(
    List<PillarInfo> pillars,
    Address address,
  ) {
    for (final pillar in pillars) {
      if (pillar.ownerAddress.equals(address)) {
        return pillar;
      }
    }
    for (final pillar in pillars) {
      if (pillar.producerAddress.equals(address)) {
        return pillar;
      }
    }
    return null;
  }

  /// Picks the protocol voting method [address] is allowed to use for
  /// [pillar]: VoteByName for the owner, VoteByProdAddress otherwise
  /// (the pillar was matched by producer address).
  static AcceleratorVoteMethod voteMethodFor(
    PillarInfo pillar,
    Address address,
  ) {
    return pillar.ownerAddress.equals(address)
        ? AcceleratorVoteMethod.byName
        : AcceleratorVoteMethod.byProdAddress;
  }
}
