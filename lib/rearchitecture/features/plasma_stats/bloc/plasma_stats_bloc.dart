import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PlasmaStatsBloc extends InfiniteListBloc<PlasmaInfoWrapper> {
  PlasmaStatsBloc({required super.zenon, super.pageSize = kPageSize})
    : super(
        fromJsonT: (Object? map) => PlasmaInfoWrapper.fromJson(
          map! as Map<String, dynamic>,
        ),
        toJsonT: (PlasmaInfoWrapper info) => info.toJson(),
      );

  @override
  Future<List<PlasmaInfoWrapper>> paginationFetch({
    required Address? address,
    required int pageIndex,
    required int pageSize,
  }) async {
    final int start = pageIndex * pageSize;
    final int end = start + pageSize;

    final int length = kDefaultAddressList.length;

    final List<String?> targetedAddresses = kDefaultAddressList.sublist(
      start,
      end < length ? end : length,
    );

    return _getPlasmas(addresses: targetedAddresses);
  }

  Future<List<PlasmaInfoWrapper>> _getPlasmas({
    required List<String?> addresses,
  }) async {
    final List<PlasmaInfoWrapper> plasmaInfoWrapper = await Future.wait(
      addresses.map((String? e) => _getPlasma(e!)).toList(),
    );

    return plasmaInfoWrapper;
  }

  Future<PlasmaInfoWrapper> _getPlasma(String address) async {
    try {
      final PlasmaInfo plasmaInfo = await zenon!.embedded.plasma.get(
        Address.parse(address),
      );
      return PlasmaInfoWrapper(address: address, plasmaInfo: plasmaInfo);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      rethrow;
    }
  }
}
