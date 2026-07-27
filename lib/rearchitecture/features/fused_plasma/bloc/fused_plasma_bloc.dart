import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/fused_plasma/model/fusion_entry_wrapper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that fetches Plasma fusion entries for a wallet address.
class FusedPlasmaBloc extends InfiniteListBloc<FusionEntryWrapper> {
  /// Creates a new [FusedPlasmaBloc].
  FusedPlasmaBloc({required super.zenon, super.pageSize = kPageSize})
    : super(
        fromJsonT: (Object? map) => FusionEntryWrapper.fromJson(
          map! as Map<String, dynamic>,
        ),
        toJsonT: (FusionEntryWrapper fusionEntryWrapper) =>
            fusionEntryWrapper.toJson(),
      );

  int? _lastMomentumHeight;

  /// The latest known momentum height, used for cancellation countdowns.
  int? get lastMomentumHeight => _lastMomentumHeight;

  @override
  Future<List<FusionEntryWrapper>> paginationFetch({
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

    return fusionEntryList.list
        .map(
          (FusionEntry fusionEntry) => FusionEntryWrapper(
            fusionEntry: fusionEntry,
            isRevocable: lastMomentum.height > fusionEntry.expirationHeight,
          ),
        )
        .toList();
  }
}
