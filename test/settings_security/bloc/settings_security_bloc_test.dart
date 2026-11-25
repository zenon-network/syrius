import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_security/settings_security.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class MockSharedPrefsService extends Mock implements SharedPrefsService {}

void main() {
  group('SettingsSecurityBloc', () {
    late MockSharedPrefsService prefs;
    late List<WalletNotification> notifications;
    late List<String> errorTitles;
    late int? previousAutoLock;
    late double? previousAutoErase;

    setUp(() {
      previousAutoLock = kAutoLockWalletMinutes;
      previousAutoErase = kAutoEraseWalletLimit;
      prefs = MockSharedPrefsService();
      notifications = <WalletNotification>[];
      errorTitles = <String>[];
      when(() => prefs.put(any(), any<dynamic>())).thenAnswer((_) async {});
    });

    tearDown(() {
      kAutoLockWalletMinutes = previousAutoLock;
      kAutoEraseWalletLimit = previousAutoErase;
    });

    SettingsSecurityBloc buildBloc({
      Future<Signature> Function(List<int> message)? signBytes,
      Future<bool> Function(
        List<int> signature,
        List<int> message,
        List<int> publicKey,
      )?
      verifySignature,
      Future<Uint8List> Function(String filePath)? readFileBytes,
    }) => SettingsSecurityBloc(
      initialAutoLockMinutes: 15,
      initialAutoEraseAttempts: 3,
      prefsService: prefs,
      signBytes:
          signBytes ?? (List<int> _) async => Signature('aabbcc', 'ddeeff'),
      verifySignature: verifySignature ?? (_, _, _) async => true,
      readFileBytes:
          readFileBytes ?? (_) async => Uint8List.fromList(<int>[1, 2, 3]),
      addNotification: (WalletNotification notification) async {
        notifications.add(notification);
      },
      reportError: (Object error, String title) async {
        errorTitles.add(title);
      },
    );

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'updates and persists auto-lock interval',
      build: buildBloc,
      act: (SettingsSecurityBloc bloc) {
        bloc
          ..add(const SettingsSecurityAutoLockChanged(minutes: 25))
          ..add(
            const SettingsSecurityAutoLockConfirmed(
              errorTitle: 'Auto-lock error',
            ),
          );
      },
      expect: () => <Matcher>[
        isA<SettingsSecurityState>().having(
          (SettingsSecurityState s) => s.autoLockMinutes,
          'autoLockMinutes',
          25,
        ),
        isA<SettingsSecurityState>().having(
          (SettingsSecurityState s) => s.isConfirmingAutoLock,
          'isConfirmingAutoLock',
          true,
        ),
        isA<SettingsSecurityState>()
            .having(
              (SettingsSecurityState s) => s.isConfirmingAutoLock,
              'isConfirmingAutoLock',
              false,
            )
            .having(
              (SettingsSecurityState s) => s.autoLockConfirmedNonce,
              'nonce',
              1,
            ),
      ],
      verify: (_) {
        verify(() => prefs.put(kAutoLockWalletMinutesKey, 25)).called(1);
        expect(kAutoLockWalletMinutes, 25);
      },
    );

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'updates and persists auto-erase limit with notification',
      build: buildBloc,
      act: (SettingsSecurityBloc bloc) {
        bloc
          ..add(const SettingsSecurityAutoEraseChanged(attempts: 7))
          ..add(
            const SettingsSecurityAutoEraseConfirmed(
              notificationTitle: 'Changed',
              notificationDetails: 'Now 7',
              errorTitle: 'Error',
            ),
          );
      },
      verify: (_) {
        verify(() => prefs.put(kAutoEraseNumAttemptsKey, 7.0)).called(1);
        expect(kAutoEraseWalletLimit, 7.0);
        expect(notifications, hasLength(1));
      },
    );

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'signs message and stores signature and public key',
      build: buildBloc,
      act: (SettingsSecurityBloc bloc) => bloc.add(
        const SettingsSecuritySignMessageRequested(
          message: 'hello zenon',
          errorTitle: 'Sign error',
        ),
      ),
      expect: () => <Matcher>[
        isA<SettingsSecurityState>().having(
          (SettingsSecurityState s) => s.isSigningMessage,
          'isSigningMessage',
          true,
        ),
        isA<SettingsSecurityState>()
            .having(
              (SettingsSecurityState s) => s.signedMessageSignature,
              'signature',
              'aabbcc',
            )
            .having(
              (SettingsSecurityState s) => s.signedMessagePublicKey,
              'publicKey',
              'ddeeff',
            ),
      ],
    );

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'verifies valid message, notifies, and increments nonce',
      build: buildBloc,
      act: (SettingsSecurityBloc bloc) => bloc.add(
        const SettingsSecurityVerifyMessageRequested(
          message: 'hello',
          signature: 'aabb',
          publicKey: 'ccdd',
          successTitle: 'Verified',
          successDetails: 'OK',
          invalidMessage: 'Invalid',
          errorTitle: 'Verify error',
        ),
      ),
      expect: () => <Matcher>[
        isA<SettingsSecurityState>().having(
          (SettingsSecurityState s) => s.isVerifyingMessage,
          'isVerifyingMessage',
          true,
        ),
        isA<SettingsSecurityState>()
            .having(
              (SettingsSecurityState s) => s.isVerifyingMessage,
              'isVerifyingMessage',
              false,
            )
            .having(
              (SettingsSecurityState s) => s.messageVerifiedNonce,
              'nonce',
              1,
            ),
      ],
      verify: (_) {
        expect(notifications, hasLength(1));
        expect(errorTitles, isEmpty);
      },
    );

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'reports error when message verification returns false',
      build: () => buildBloc(verifySignature: (_, _, _) async => false),
      act: (SettingsSecurityBloc bloc) => bloc.add(
        const SettingsSecurityVerifyMessageRequested(
          message: 'hello',
          signature: 'aabb',
          publicKey: 'ccdd',
          successTitle: 'Verified',
          successDetails: 'OK',
          invalidMessage: 'Invalid',
          errorTitle: 'Verify error',
        ),
      ),
      verify: (_) {
        expect(errorTitles, <String>['Verify error']);
        expect(notifications, isEmpty);
      },
    );

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'signs file digest and increments fileSignedNonce',
      build: buildBloc,
      act: (SettingsSecurityBloc bloc) => bloc.add(
        const SettingsSecuritySignFileRequested(
          filePath: '/tmp/sample.bin',
          errorTitle: 'Sign file error',
        ),
      ),
      expect: () => <Matcher>[
        isA<SettingsSecurityState>().having(
          (SettingsSecurityState s) => s.isSigningFile,
          'isSigningFile',
          true,
        ),
        isA<SettingsSecurityState>()
            .having(
              (SettingsSecurityState s) => s.signedFileHash,
              'signedFileHash',
              'aabbcc',
            )
            .having(
              (SettingsSecurityState s) => s.signedFilePublicKey,
              'signedFilePublicKey',
              'ddeeff',
            )
            .having(
              (SettingsSecurityState s) => s.fileSignedNonce,
              'fileSignedNonce',
              1,
            ),
      ],
    );

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'verifies file hash and increments fileVerifiedNonce',
      build: buildBloc,
      act: (SettingsSecurityBloc bloc) => bloc.add(
        const SettingsSecurityVerifyFileRequested(
          filePath: '/tmp/sample.bin',
          signedHash: 'aabb',
          publicKey: 'ccdd',
          successTitle: 'File verified',
          successDetails: 'OK',
          invalidMessage: 'Invalid hash',
          errorTitle: 'Verify file error',
        ),
      ),
      expect: () => <Matcher>[
        isA<SettingsSecurityState>().having(
          (SettingsSecurityState s) => s.isVerifyingFile,
          'isVerifyingFile',
          true,
        ),
        isA<SettingsSecurityState>()
            .having(
              (SettingsSecurityState s) => s.isVerifyingFile,
              'isVerifyingFile',
              false,
            )
            .having(
              (SettingsSecurityState s) => s.fileVerifiedNonce,
              'fileVerifiedNonce',
              1,
            ),
      ],
      verify: (_) {
        expect(notifications, hasLength(1));
        expect(errorTitles, isEmpty);
      },
    );
  });
}
