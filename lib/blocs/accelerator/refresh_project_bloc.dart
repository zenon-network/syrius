import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class RefreshProjectBloc extends BaseBloc<Project?> {
  Future<void> refreshProject(Hash projectId) async {
    try {
      addEvent(null);
      addEvent(
        await zenon!.embedded.accelerator.getProjectById(projectId.toString()),
      );
    } catch (e) {
      addError(e);
    }
  }
}
