import 'package:flutter_test/flutter_test.dart';
import 'package:mutex/mutex.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _ThrowingWallet implements Wallet {
  _ThrowingWallet(this._error);

  final Error _error;

  @override
  Future<WalletAccount> getAccount([int accountIndex = 0]) async {
    throw _error;
  }
}

class _TestWalletFile extends WalletFile {
  _TestWalletFile({this.wallet, this.openError}) : super('/tmp/test-wallet');

  final Wallet? wallet;
  final Exception? openError;
  final Mutex _lock = Mutex();
  int releaseCalls = 0;

  @override
  String get walletType => keyStoreWalletType;

  @override
  bool get isOpen => _lock.isLocked;

  @override
  bool get isHardwareWallet => false;

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) {
    return _lock.protect<T>(() async {
      if (openError != null) {
        throw openError!;
      }
      try {
        return await accessSection(wallet!);
      } finally {
        releaseCalls++;
      }
    });
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('ZenonAddressUtils.generateNewAddress', () {
    late WalletFile? previousWalletFile;
    late List<String?> previousAddressList;

    setUp(() {
      previousWalletFile = kWalletFile;
      previousAddressList = List<String?>.from(kDefaultAddressList);
    });

    tearDown(() {
      kWalletFile = previousWalletFile;
      kDefaultAddressList = previousAddressList;
    });

    test('throws SyriusException when wallet is not unlocked', () async {
      kWalletFile = null;

      await expectLater(
        ZenonAddressUtils.generateNewAddress,
        throwsA(isA<SyriusException>()),
      );
    });

    test('rethrows errors from walletFile.open without swallowing', () async {
      final _TestWalletFile walletFile = _TestWalletFile(
        openError: WalletException('device disconnected'),
      );
      kWalletFile = walletFile;

      await expectLater(
        ZenonAddressUtils.generateNewAddress,
        throwsA(
          isA<WalletException>().having(
            (WalletException e) => e.message,
            'message',
            'device disconnected',
          ),
        ),
      );
      expect(walletFile.isOpen, isFalse);
    });

    test(
      'rethrows errors from wallet.getAccount and closes wallet lock',
      () async {
        final _TestWalletFile walletFile = _TestWalletFile(
          wallet: _ThrowingWallet(StateError('derivation failed')),
        );
        kWalletFile = walletFile;
        kDefaultAddressList = <String?>[
          'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
        ];

        await expectLater(
          ZenonAddressUtils.generateNewAddress,
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              'derivation failed',
            ),
          ),
        );
        expect(walletFile.isOpen, isFalse);
        expect(walletFile.releaseCalls, 1);
      },
    );
  });
}
