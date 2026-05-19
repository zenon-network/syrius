import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class GetPillarsByOwnerBloc extends FetchBloc<List<PillarInfo>> {
  GetPillarsByOwnerBloc({required super.zenon})
      : super(
          fromJsonT: (Map<String, dynamic> data) =>
              List<Map<String, dynamic>>.from(
                      data['list'] as List<Map<String, dynamic>>)
                  .map(PillarInfo.fromJson)
                  .toList(),
          toJsonT: (List<PillarInfo> list) => {
            'list': list.map((PillarInfo entry) => entry.toJson()).toList(),
          },
        );

  @override
  Future<List<PillarInfo>> getData({required Address address}) =>
      zenon.embedded.pillar.getByOwner(address);
}
