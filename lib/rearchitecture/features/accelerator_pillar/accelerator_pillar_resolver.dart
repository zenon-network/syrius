import 'package:equatable/equatable.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// How an address is authorized to cast a Pillar vote on an Accelerator hash.
enum AcceleratorVoteMethod {
  /// VoteByName — only the Pillar's owner (stake) address may send it.
  byName,

  /// VoteByProdAddress — only the Pillar's block-producing address may send it.
  /// On-chain, the vote is recorded under the Pillar's name, same as
  /// [byName].
  byProdAddress,
}

/// The result of resolving the Pillar associated with an address.
class ResolvedPillarResult extends Equatable {
  /// Creates a [ResolvedPillarResult].
  const ResolvedPillarResult({
    required this.pillarInfo,
    this.activePillarCount,
  });

  /// The Pillar owned or produced by the address, or `null` if none matched.
  final PillarInfo? pillarInfo;

  /// Total active Pillar count observed during resolution, when available.
  final int? activePillarCount;

  @override
  List<Object?> get props => <Object?>[pillarInfo, activePillarCount];
}

/// Default RPC page size used when paging through `embedded.pillar.getAll`.
const int kPillarRegistryPageSize = 512;

/// Pages through the full Pillar registry via `embedded.pillar.getAll`.
Future<List<PillarInfo>> fetchAllPillars({
  required Zenon zenon,
  int pageSize = kPillarRegistryPageSize,
}) async {
  final List<PillarInfo> pillars = <PillarInfo>[];
  int pageIndex = 0;

  while (true) {
    final PillarInfoList page = await zenon.embedded.pillar.getAll(
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    pillars.addAll(page.list);
    if (page.list.length < pageSize) {
      break;
    }
    pageIndex += 1;
  }

  return pillars;
}

/// Returns the Pillar that [address] owns or produces, or `null` when the
/// address has no Pillar role.
///
/// An owner match takes precedence over a producer match when an address holds
/// both roles across Pillars.
PillarInfo? pillarForAddress(List<PillarInfo> pillars, Address address) {
  for (final PillarInfo pillar in pillars) {
    if (pillar.ownerAddress.equals(address)) {
      return pillar;
    }
  }
  for (final PillarInfo pillar in pillars) {
    if (pillar.producerAddress.equals(address)) {
      return pillar;
    }
  }
  return null;
}

/// Selects the protocol voting method that [address] must use for [pillar].
///
/// Returns [AcceleratorVoteMethod.byName] when [address] is the Pillar's owner
/// address and [AcceleratorVoteMethod.byProdAddress] otherwise.
AcceleratorVoteMethod voteMethodFor(PillarInfo pillar, Address address) {
  return pillar.ownerAddress.equals(address)
      ? AcceleratorVoteMethod.byName
      : AcceleratorVoteMethod.byProdAddress;
}

/// Resolves the Pillar associated with [address], preferring an owner match
/// via `getByOwner` and falling back to paging through `pillar.getAll` for
/// producer-address matching when `getByOwner` returns empty.
Future<ResolvedPillarResult> resolvePillarForAddress({
  required Zenon zenon,
  required Address address,
  int pageSize = kPillarRegistryPageSize,
}) async {
  final List<PillarInfo> ownedPillars = await zenon.embedded.pillar.getByOwner(
    address,
  );
  if (ownedPillars.isNotEmpty) {
    return ResolvedPillarResult(
      pillarInfo: pillarForAddress(ownedPillars, address) ?? ownedPillars.first,
    );
  }

  final List<PillarInfo> allPillars = await fetchAllPillars(
    zenon: zenon,
    pageSize: pageSize,
  );
  return ResolvedPillarResult(
    pillarInfo: pillarForAddress(allPillars, address),
    activePillarCount: allPillars.length,
  );
}
