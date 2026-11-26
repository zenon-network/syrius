import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Hex-encoded signature and corresponding public key produced by [walletSign].
class Signature {
  /// Creates a [Signature] with hex-encoded [signature] and [publicKey].
  Signature(this.signature, this.publicKey);

  /// Hex-encoded ed25519 signature bytes.
  String signature;

  /// Hex-encoded ed25519 public key bytes.
  String publicKey;
}

/// Signs [message] using the wallet account for [address] (or
/// [kSelectedAddress] when omitted).
Future<Signature> walletSign(
  List<int> message, {
  String? address,
}) async {
  final String? signerAddress = address ?? kSelectedAddress;
  final int signerIndex = kDefaultAddressList.indexOf(signerAddress);

  if (signerAddress == null || signerIndex < 0) {
    throw StateError('Unable to resolve signing address: $signerAddress');
  }

  final WalletFile? walletFile = kWalletFile;
  if (walletFile == null) {
    throw WalletException('Wallet is not unlocked.');
  }

  return await walletFile.access<Signature>((Wallet wallet) async {
    final WalletAccount walletAccount = await wallet.getAccount(signerIndex);
    final List<int> publicKey = await walletAccount.getPublicKey();
    final List<int> signature = await walletAccount.sign(
      Uint8List.fromList(message),
    );
    return Signature(
      BytesUtils.bytesToHex(signature),
      BytesUtils.bytesToHex(publicKey),
    );
  });
}

/// Loads and JSON-decodes an asset file at [filePath].
Future<dynamic> loadJsonFromAssets(String filePath) async {
  final String jsonString = await rootBundle.loadString(filePath);
  return jsonDecode(jsonString);
}
