import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that fetches Plasma fusion entries for a wallet address.
class FusedPlasmaBloc extends InfiniteListBloc<FusionEntry> {
  /// Creates a new [FusedPlasmaBloc].
  FusedPlasmaBloc({required super.zenon, super.pageSize = kPageSize})
    : super(
        fromJsonT: (Object? map) => FusionEntry.fromJson(
          map! as Map<String, dynamic>,
        ),
        toJsonT: (FusionEntry fusionEntry) => fusionEntry.toJson(),
      );

  int? _lastMomentumHeight;

  /// The latest known momentum height, used for cancellation countdowns.
  int? get lastMomentumHeight => _lastMomentumHeight;

  @override
  Future<List<FusionEntry>> paginationFetch({
    required Address? address,
    required int pageIndex,
    required int pageSize,
  }) async {
    final FusionEntryList fusionEntryList = await zenon.embedded.plasma
        .getEntriesByAddress(
          address!,
          pageIndex: pageIndex,
          pageSize: pageSize,
        );
    final Momentum lastMomentum = await zenon.ledger.getFrontierMomentum();
    _lastMomentumHeight = lastMomentum.height;

    for (final FusionEntry fusionEntry in fusionEntryList.list) {
      fusionEntry.isRevocable =
          lastMomentum.height > fusionEntry.expirationHeight;
    }

    return fusionEntryList.list;
  }
}
