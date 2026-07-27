import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

// TODO(maznnwell): check if this documentation is correct
/// Only one pilar per owner is allowed
///
/// Hence the RPC 'embedded.pillar.getByOwner' will return an empty list if
/// an address isn't register as an owner for any pillar, or a list containing
/// one element if it is
class PillarsByOwnerBloc extends FetchBloc<List<PillarInfo>> {
  /// {@macro default_constructor}
  PillarsByOwnerBloc({required super.zenon})
    : super(
        fromJsonT: (Map<String, dynamic> data) =>
            List.castFrom<dynamic, Map<String, dynamic>>(
              data['list'],
            ).map(PillarInfo.fromJson).toList(),
        toJsonT: (List<PillarInfo> list) => <String, dynamic>{
          'list': list.map((PillarInfo entry) => entry.toJson()).toList(),
        },
      );

  @override
  Future<List<PillarInfo>> getData({required Address address}) =>
      zenon.embedded.pillar.getByOwner(address);
}
