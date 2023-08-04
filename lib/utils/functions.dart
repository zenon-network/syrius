import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Future<String> walletSign(List<int> message) async {
  List<int> signature = await zenon!.defaultKeyPair!.sign(
    Uint8List.fromList(
      message,
    ),
  );

  return BytesUtils.bytesToHex(signature);
}