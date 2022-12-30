import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TokensBloc extends BaseBloc<List<Token>?> with RefreshBlocMixin {
  TokensBloc() {
    zenon!.wsClient.restartedStream.listen(
      (restarted) {
        if (restarted) {
          getDataAsync();
        }
      },
    );
  }

  Future<void> getDataAsync() async {
    try {
      addEvent(null);
      addEvent((await zenon!.embedded.token.getAll()).list);
    } catch (e) {
      addError(e);
    }
  }
}
