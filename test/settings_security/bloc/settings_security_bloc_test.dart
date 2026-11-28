import 'dart:async';
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
    late bool? previousAutoEraseEnabled;

    setUp(() {
      previousAutoLock = kAutoLockWalletMinutes;
      previousAutoErase = kAutoEraseWalletLimit;
      previousAutoEraseEnabled = kAutoEraseWalletEnabled;
      prefs = MockSharedPrefsService();
      notifications = <WalletNotification>[];
      errorTitles = <String>[];
      when(() => prefs.put(any(), any<dynamic>())).thenAnswer((_) async {});
    });

    tearDown(() {
      kAutoLockWalletMinutes = previousAutoLock;
      kAutoEraseWalletLimit = previousAutoErase;
      kAutoEraseWalletEnabled = previousAutoEraseEnabled;
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

    test(
      'activates captured auto-lock value when slider moves during write',
      () async {
        final Completer<void> writeCompleter = Completer<void>();
        when(
          () => prefs.put(kAutoLockWalletMinutesKey, any<dynamic>()),
        ).thenAnswer((_) => writeCompleter.future);

        final SettingsSecurityBloc bloc = buildBloc();
        addTearDown(bloc.close);

        bloc
          ..add(const SettingsSecurityAutoLockChanged(minutes: 10))
          ..add(
            const SettingsSecurityAutoLockConfirmed(
              errorTitle: 'Auto-lock error',
            ),
          );
        await Future<void>.delayed(Duration.zero);

        // User moves slider to 30 while persistence of 10 is still in flight.
        bloc.add(const SettingsSecurityAutoLockChanged(minutes: 30));
        await Future<void>.delayed(Duration.zero);

        writeCompleter.complete();
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SettingsSecurityState>().having(
              (SettingsSecurityState s) => s.autoLockConfirmedNonce,
              'nonce',
              1,
            ),
          ),
        );

        verify(() => prefs.put(kAutoLockWalletMinutesKey, 10)).called(1);
        expect(kAutoLockWalletMinutes, 10);
        expect(bloc.state.autoLockMinutes, 30);
      },
    );

    test(
      'activates captured auto-erase value when slider moves during write',
      () async {
        final Completer<void> writeCompleter = Completer<void>();
        when(
          () => prefs.put(kAutoEraseNumAttemptsKey, any<dynamic>()),
        ).thenAnswer((_) => writeCompleter.future);

        final SettingsSecurityBloc bloc = buildBloc();
        addTearDown(bloc.close);

        bloc
          ..add(const SettingsSecurityAutoEraseChanged(attempts: 4))
          ..add(
            const SettingsSecurityAutoEraseConfirmed(
              notificationTitle: 'Changed',
              notificationDetails: 'Now 4',
              errorTitle: 'Error',
            ),
          );
        await Future<void>.delayed(Duration.zero);

        // User moves slider to 10 while persistence of 4 is still in flight.
        bloc.add(const SettingsSecurityAutoEraseChanged(attempts: 10));
        await Future<void>.delayed(Duration.zero);

        writeCompleter.complete();
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SettingsSecurityState>().having(
              (SettingsSecurityState s) => s.isConfirmingAutoErase,
              'isConfirmingAutoErase',
              false,
            ),
          ),
        );

        verify(() => prefs.put(kAutoEraseNumAttemptsKey, 4.0)).called(1);
        expect(kAutoEraseWalletLimit, 4.0);
        expect(bloc.state.autoEraseAttempts, 10.0);
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

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'persists auto-erase Off via separate enabled flag while keeping a '
      'positive legacy threshold for downgrade safety',
      setUp: () {
        kAutoEraseWalletLimit = 5.0;
        kAutoEraseWalletEnabled = true;
      },
      build: buildBloc,
      act: (SettingsSecurityBloc bloc) {
        bloc
          ..add(const SettingsSecurityAutoEraseChanged(attempts: 0))
          ..add(
            const SettingsSecurityAutoEraseConfirmed(
              notificationTitle: 'Changed',
              notificationDetails: 'Off',
              errorTitle: 'Error',
            ),
          );
      },
      verify: (_) {
        verify(() => prefs.put(kAutoEraseEnabledKey, false)).called(1);
        verify(() => prefs.put(kAutoEraseNumAttemptsKey, 5.0)).called(1);
        expect(kAutoEraseWalletEnabled, isFalse);
        expect(kAutoEraseWalletLimit, 5.0);
      },
    );

    blocTest<SettingsSecurityBloc, SettingsSecurityState>(
      'restores committed auto-erase policy when persistence fails',
      setUp: () {
        when(
          () => prefs.put(kAutoEraseNumAttemptsKey, any<dynamic>()),
        ).thenThrow(Exception('disk full'));
      },
      build: buildBloc,
      act: (SettingsSecurityBloc bloc) {
        bloc
          ..add(const SettingsSecurityAutoEraseChanged(attempts: 10))
          ..add(
            const SettingsSecurityAutoEraseConfirmed(
              notificationTitle: 'Changed',
              notificationDetails: 'Now 10',
              errorTitle: 'Save failed',
            ),
          );
      },
      verify: (SettingsSecurityBloc bloc) {
        expect(bloc.state.autoEraseAttempts, 3.0);
        expect(bloc.state.isConfirmingAutoErase, isFalse);
        expect(errorTitles, <String>['Save failed']);
      },
    );

    test(
      'rolls back persisted auto-erase threshold when enabled-flag write fails '
      'so startup restores committed policy',
      () async {
        final Map<String, dynamic> stored = <String, dynamic>{
          kAutoEraseNumAttemptsKey: 3.0,
          kAutoEraseEnabledKey: true,
        };
        kAutoEraseWalletLimit = 3.0;
        kAutoEraseWalletEnabled = true;

        when(
          () => prefs.get(
            any(),
            defaultValue: any<dynamic>(named: 'defaultValue'),
          ),
        ).thenAnswer((Invocation inv) {
          final String key = inv.positionalArguments.first as String;
          return stored.containsKey(key)
              ? stored[key]
              : inv.namedArguments[#defaultValue];
        });
        when(() => prefs.put(kAutoEraseNumAttemptsKey, any<dynamic>()))
            .thenAnswer((Invocation inv) async {
              stored[kAutoEraseNumAttemptsKey] = inv.positionalArguments[1];
            });
        when(
          () => prefs.put(kAutoEraseEnabledKey, any<dynamic>()),
        ).thenThrow(Exception('disk full on enabled flag'));

        final SettingsSecurityBloc bloc = buildBloc();
        addTearDown(bloc.close);

        bloc
          ..add(const SettingsSecurityAutoEraseChanged(attempts: 10))
          ..add(
            const SettingsSecurityAutoEraseConfirmed(
              notificationTitle: 'Changed',
              notificationDetails: 'Now 10',
              errorTitle: 'Save failed',
            ),
          );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SettingsSecurityState>()
                .having(
                  (SettingsSecurityState s) => s.isConfirmingAutoErase,
                  'isConfirmingAutoErase',
                  false,
                )
                .having(
                  (SettingsSecurityState s) => s.autoEraseAttempts,
                  'autoEraseAttempts',
                  3.0,
                ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(kAutoEraseWalletLimit, 3.0);
        expect(kAutoEraseWalletEnabled, isTrue);
        expect(errorTitles, <String>['Save failed']);

        // Simulate startup policy restoration from persisted preferences.
        final double restoredLimit =
            prefs.get(
                  kAutoEraseNumAttemptsKey,
                  defaultValue: kAutoEraseNumAttemptsDefault,
                )
                as double;
        final bool restoredEnabled =
            prefs.get(
                  kAutoEraseEnabledKey,
                  defaultValue: restoredLimit > 0,
                )
                as bool;
        expect(restoredLimit, 3.0);
        expect(restoredEnabled, isTrue);
      },
    );

    test(
      'reflects persisted threshold when rollback write also fails',
      () async {
        final Map<String, dynamic> stored = <String, dynamic>{
          kAutoEraseNumAttemptsKey: 3.0,
          kAutoEraseEnabledKey: true,
        };
        kAutoEraseWalletLimit = 3.0;
        kAutoEraseWalletEnabled = true;
        int thresholdWrites = 0;

        when(
          () => prefs.get(
            any(),
            defaultValue: any<dynamic>(named: 'defaultValue'),
          ),
        ).thenAnswer((Invocation inv) {
          final String key = inv.positionalArguments.first as String;
          return stored.containsKey(key)
              ? stored[key]
              : inv.namedArguments[#defaultValue];
        });
        when(() => prefs.put(kAutoEraseNumAttemptsKey, any<dynamic>()))
            .thenAnswer((Invocation inv) async {
              thresholdWrites += 1;
              if (thresholdWrites == 1) {
                stored[kAutoEraseNumAttemptsKey] = inv.positionalArguments[1];
                return;
              }
              throw Exception('rollback failed');
            });
        when(
          () => prefs.put(kAutoEraseEnabledKey, any<dynamic>()),
        ).thenThrow(Exception('disk full on enabled flag'));

        final SettingsSecurityBloc bloc = buildBloc();
        addTearDown(bloc.close);

        bloc
          ..add(const SettingsSecurityAutoEraseChanged(attempts: 10))
          ..add(
            const SettingsSecurityAutoEraseConfirmed(
              notificationTitle: 'Changed',
              notificationDetails: 'Now 10',
              errorTitle: 'Save failed',
            ),
          );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<SettingsSecurityState>()
                .having(
                  (SettingsSecurityState s) => s.isConfirmingAutoErase,
                  'isConfirmingAutoErase',
                  false,
                )
                .having(
                  (SettingsSecurityState s) => s.autoEraseAttempts,
                  'autoEraseAttempts',
                  10.0,
                ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(stored[kAutoEraseNumAttemptsKey], 10.0);
        expect(kAutoEraseWalletLimit, 10.0);
        expect(kAutoEraseWalletEnabled, isTrue);
        expect(errorTitles, <String>['Save failed']);
      },
    );
  });
}
