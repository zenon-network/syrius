import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/dashboard_base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsBloc extends DashboardBaseBloc<List<SentinelInfo>> {
  @override
  Future<List<SentinelInfo>> makeAsyncCall() async =>
      (await zenon!.embedded.sentinel.getAllActive()).list;
}
