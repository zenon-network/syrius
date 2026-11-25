import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockKeyStoreWalletFile extends Mock implements KeyStoreWalletFile {}

class _MockLedgerWalletFile extends Mock implements LedgerWalletFile {}

class _MockWalletManager extends Mock implements WalletManager {}

class _MockLedgerWallet extends Mock implements LedgerWallet {}

class _MockLedgerWalletAccount extends Mock implements LedgerWalletAccount {}

class _FakeWalletDefinition extends Fake implements WalletDefinition {
  _FakeWalletDefinition({required this.walletId, required this.walletName});

  @override
  final String walletId;

  @override
  final String walletName;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      _FakeWalletDefinition(walletId: 'fallback', walletName: 'Fallback'),
    );
  });

  group('KeyStoreFileBloc', () {
    late _MockKeyStoreWalletFile walletFile;
    late List<int>? receivedCipherKey;

    setUp(() {
      walletFile = _MockKeyStoreWalletFile();
      receivedCipherKey = null;
    });

    blocTest<KeyStoreFileBloc, KeyStoreFileState>(
      'emits [loading, success] on keystore creation and wallet init',
      build: () => KeyStoreFileBloc(
        createKeyStoreWalletFile: (String mnemonic, String password) async {
          expect(mnemonic, 'seed words');
          expect(password, 'StrongPass1!');
        },
        initWalletAfterDecryption: (List<int> cipherKey) async {
          receivedCipherKey = cipherKey;
        },
        getWalletFile: () => walletFile,
      ),
      act: (KeyStoreFileBloc bloc) => bloc.add(
        const KeyStoreFileCreateRequested(
          mnemonic: 'seed words',
          password: 'StrongPass1!',
        ),
      ),
      expect: () => <KeyStoreFileState>[
        const KeyStoreFileLoading(),
        KeyStoreFileSuccess(walletFile: walletFile),
      ],
      verify: (_) {
        expect(receivedCipherKey, Crypto.digest(utf8.encode('StrongPass1!')));
      },
    );

    blocTest<KeyStoreFileBloc, KeyStoreFileState>(
      'emits [loading, failure] when creation throws',
      build: () => KeyStoreFileBloc(
        createKeyStoreWalletFile: (_, _) =>
            Future<void>.error(Exception('disk full')),
        initWalletAfterDecryption: (_) async {},
        getWalletFile: () => walletFile,
      ),
      act: (KeyStoreFileBloc bloc) => bloc.add(
        const KeyStoreFileCreateRequested(
          mnemonic: 'seed words',
          password: 'StrongPass1!',
        ),
      ),
      expect: () => <Matcher>[
        isA<KeyStoreFileLoading>(),
        isA<KeyStoreFileFailure>().having(
          (KeyStoreFileFailure s) => s.error.toString(),
          'error',
          contains('disk full'),
        ),
      ],
    );

    blocTest<KeyStoreFileBloc, KeyStoreFileState>(
      'emits [loading, failure] when wallet file is not a KeyStoreWalletFile',
      build: () => KeyStoreFileBloc(
        createKeyStoreWalletFile: (_, _) async {},
        initWalletAfterDecryption: (_) async {},
        getWalletFile: () => null,
      ),
      act: (KeyStoreFileBloc bloc) => bloc.add(
        const KeyStoreFileCreateRequested(
          mnemonic: 'seed words',
          password: 'StrongPass1!',
        ),
      ),
      expect: () => <Matcher>[
        isA<KeyStoreFileLoading>(),
        isA<KeyStoreFileFailure>(),
      ],
    );
  });

  group('LedgerWalletFileBloc', () {
    late _MockLedgerWalletFile walletFile;
    late String? passedName;

    setUp(() {
      walletFile = _MockLedgerWalletFile();
      passedName = null;
    });

    blocTest<LedgerWalletFileBloc, LedgerWalletFileState>(
      'emits [loading, success] on Ledger wallet creation and wallet init',
      build: () => LedgerWalletFileBloc(
        createLedgerWalletFile:
            (String walletId, String password, {String? walletName}) async {
              expect(walletId, 'ledger-1');
              expect(password, 'StrongPass1!');
              passedName = walletName;
            },
        initWalletAfterDecryption: (_) async {},
        getWalletFile: () => walletFile,
      ),
      act: (LedgerWalletFileBloc bloc) => bloc.add(
        const LedgerWalletFileCreateRequested(
          walletId: 'ledger-1',
          password: 'StrongPass1!',
          walletName: 'Nano X',
        ),
      ),
      expect: () => <LedgerWalletFileState>[
        const LedgerWalletFileLoading(),
        LedgerWalletFileSuccess(walletFile: walletFile),
      ],
      verify: (_) {
        expect(passedName, 'Nano X');
      },
    );

    blocTest<LedgerWalletFileBloc, LedgerWalletFileState>(
      'emits [loading, failure] when Ledger creation throws',
      build: () => LedgerWalletFileBloc(
        createLedgerWalletFile: (_, _, {String? walletName}) =>
            Future<void>.error(
              const LedgerError.connectionError(origMessage: 'No device'),
            ),
        initWalletAfterDecryption: (_) async {},
        getWalletFile: () => walletFile,
      ),
      act: (LedgerWalletFileBloc bloc) => bloc.add(
        const LedgerWalletFileCreateRequested(
          walletId: 'ledger-1',
          password: 'StrongPass1!',
        ),
      ),
      expect: () => <Matcher>[
        isA<LedgerWalletFileLoading>(),
        isA<LedgerWalletFileFailure>().having(
          (LedgerWalletFileFailure s) => s.error,
          'error',
          isA<LedgerError>(),
        ),
      ],
    );
  });

  group('HardwareWalletDeviceBloc', () {
    final Address testAddress = Address.parse(
      'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
    );
    late _MockWalletManager walletManager;
    late _MockLedgerWallet ledgerWallet;
    late _MockLedgerWalletAccount ledgerAccount;
    late int clearBoxCalls;
    late List<WalletNotification> notifications;
    final _FakeWalletDefinition device1 = _FakeWalletDefinition(
      walletId: 'usb-1',
      walletName: 'Nano S Plus',
    );

    HardwareWalletDeviceBloc buildBloc() {
      return HardwareWalletDeviceBloc(
        walletManagers: <WalletManager>[walletManager],
        clearAddressesBox: () async => clearBoxCalls += 1,
        sendNotification: (WalletNotification n) async => notifications.add(n),
      );
    }

    setUp(() {
      walletManager = _MockWalletManager();
      ledgerWallet = _MockLedgerWallet();
      ledgerAccount = _MockLedgerWalletAccount();
      clearBoxCalls = 0;
      notifications = <WalletNotification>[];

      when(
        () => walletManager.getWalletDefinitions(),
      ).thenAnswer((_) async => <WalletDefinition>[device1]);
      when(
        () => walletManager.supportsWallet(any()),
      ).thenAnswer((_) async => true);
      when(
        () => walletManager.getWallet(any()),
      ).thenAnswer((_) async => ledgerWallet);
      when(
        () => ledgerWallet.getAccount(),
      ).thenAnswer((_) async => ledgerAccount);
      when(
        () => ledgerAccount.getAddress(true),
      ).thenAnswer((_) async => testAddress);
      when(() => ledgerWallet.disconnect()).thenAnswer((_) async {});
    });

    test('HardwareWalletDeviceInitialized clears addresses box', () async {
      final HardwareWalletDeviceBloc bloc = buildBloc()
        ..add(const HardwareWalletDeviceInitialized());
      addTearDown(bloc.close);

      await Future<void>.delayed(Duration.zero);
      expect(clearBoxCalls, 1);
    });

    blocTest<HardwareWalletDeviceBloc, HardwareWalletDeviceState>(
      'scans connected devices and populates device list',
      build: buildBloc,
      act: (HardwareWalletDeviceBloc bloc) =>
          bloc.add(const HardwareWalletDevicesScanRequested()),
      expect: () => <HardwareWalletDeviceState>[
        const HardwareWalletDeviceState(isScanning: true),
        HardwareWalletDeviceState(
          devices: <WalletDefinition>[device1],
          deviceMessages: <String, String?>{device1.walletId: null},
        ),
      ],
    );

    blocTest<HardwareWalletDeviceBloc, HardwareWalletDeviceState>(
      'connects to selected Ledger device, notifies, resolves address, and '
      'disconnects',
      build: buildBloc,
      act: (HardwareWalletDeviceBloc bloc) => bloc
        ..add(const HardwareWalletDevicesScanRequested())
        ..add(
          HardwareWalletDeviceSelected(
            device: device1,
            confirmAddressTitle: 'Confirm on device',
            confirmAddressDetails: 'Index 0',
            notConnectedMessage: 'Not connected',
            errorMessageBuilder: (String e) => 'Error: $e',
          ),
        ),
      expect: () => <HardwareWalletDeviceState>[
        const HardwareWalletDeviceState(isScanning: true),
        HardwareWalletDeviceState(
          devices: <WalletDefinition>[device1],
          deviceMessages: <String, String?>{device1.walletId: null},
        ),
        HardwareWalletDeviceState(
          devices: <WalletDefinition>[device1],
          deviceMessages: <String, String?>{device1.walletId: null},
          isConnecting: true,
        ),
        HardwareWalletDeviceState(
          devices: <WalletDefinition>[device1],
          selectedDevice: device1,
          deviceMessages: <String, String?>{
            device1.walletId: testAddress.toString(),
          },
        ),
      ],
      verify: (_) {
        expect(notifications, hasLength(1));
        expect(notifications.single.type, NotificationType.confirm);
        verify(() => ledgerWallet.disconnect()).called(1);
      },
    );

    blocTest<HardwareWalletDeviceBloc, HardwareWalletDeviceState>(
      'records notConnectedMessage when no manager supports device',
      setUp: () {
        when(
          () => walletManager.supportsWallet(any()),
        ).thenAnswer((_) async => false);
      },
      build: buildBloc,
      act: (HardwareWalletDeviceBloc bloc) => bloc
        ..add(const HardwareWalletDevicesScanRequested())
        ..add(
          HardwareWalletDeviceSelected(
            device: device1,
            confirmAddressTitle: 'Confirm on device',
            confirmAddressDetails: 'Index 0',
            notConnectedMessage: 'Not connected',
            errorMessageBuilder: (String e) => 'Error: $e',
          ),
        ),
      expect: () => <HardwareWalletDeviceState>[
        const HardwareWalletDeviceState(isScanning: true),
        HardwareWalletDeviceState(
          devices: <WalletDefinition>[device1],
          deviceMessages: <String, String?>{device1.walletId: null},
        ),
        HardwareWalletDeviceState(
          devices: <WalletDefinition>[device1],
          deviceMessages: <String, String?>{device1.walletId: null},
          isConnecting: true,
        ),
        HardwareWalletDeviceState(
          devices: <WalletDefinition>[device1],
          deviceMessages: <String, String?>{device1.walletId: 'Not connected'},
        ),
      ],
    );

    blocTest<HardwareWalletDeviceBloc, HardwareWalletDeviceState>(
      'maps unexpected errors and still disconnects Ledger wallet',
      setUp: () {
        when(
          () => ledgerAccount.getAddress(true),
        ).thenThrow(Exception('user rejected'));
      },
      build: buildBloc,
      act: (HardwareWalletDeviceBloc bloc) => bloc
        ..add(const HardwareWalletDevicesScanRequested())
        ..add(
          HardwareWalletDeviceSelected(
            device: device1,
            confirmAddressTitle: 'Confirm on device',
            confirmAddressDetails: 'Index 0',
            notConnectedMessage: 'Not connected',
            errorMessageBuilder: (String e) => 'Error: $e',
          ),
        ),
      verify: (HardwareWalletDeviceBloc bloc) {
        expect(bloc.state.selectedDevice, isNull);
        expect(
          bloc.state.deviceMessages[device1.walletId],
          contains('user rejected'),
        );
        verify(() => ledgerWallet.disconnect()).called(1);
      },
    );
  });
}
