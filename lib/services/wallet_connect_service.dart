import 'package:znn_sdk_dart/znn_sdk_dart.dart';

abstract class WalletConnectService {
  Future<void> signMessage(String message);

  Future<void> sendTx(
    String fromAddress,
    AccountBlockTemplate accountBlockTemplate,
  );

  void init();
}
