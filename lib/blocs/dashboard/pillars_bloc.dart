import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class PillarsBloc extends DashboardBaseBloc<int> {
  @override
  Future<int> makeAsyncCall() async {
    final numOfPillars = (await zenon!.embedded.pillar.getAll()).list.length;
    kNumOfPillars = numOfPillars;
    return numOfPillars;
  }
}
