import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';

class _MockWalletFile extends Mock implements WalletFile {}

class _MockKeyStoreWalletFile extends Mock implements KeyStoreWalletFile {}

class _MockLedgerWalletFile extends Mock implements LedgerWalletFile {}

void main() {
  group('WalletUtils WalletFile lifecycle', () {
    late WalletFile? originalWalletFile;
    late String? originalWalletPath;

    setUp(() {
      originalWalletFile = kWalletFile;
      originalWalletPath = kWalletPath;
      kWalletFile = null;
      kWalletPath = null;
    });

    tearDown(() {
      kWalletFile = originalWalletFile;
      kWalletPath = originalWalletPath;
    });

    test('setWalletFile replaces kWalletFile and closes distinct previous '
        'instance', () async {
      final _MockWalletFile previous = _MockWalletFile();
      final _MockWalletFile next = _MockWalletFile();
      when(previous.close).thenAnswer((_) async {});
      when(next.close).thenAnswer((_) async {});

      kWalletFile = previous;

      await WalletUtils.setWalletFile(next);

      expect(kWalletFile, same(next));
      verify(previous.close).called(1);
      verifyNever(next.close);
    });

    test('setWalletFile does not close wallet when replaced with identical '
        'instance', () async {
      final _MockWalletFile active = _MockWalletFile();
      when(active.close).thenAnswer((_) async {});

      kWalletFile = active;

      await WalletUtils.setWalletFile(active);

      expect(kWalletFile, same(active));
      verifyNever(active.close);
    });

    test(
      'setWalletFile closes previous wallet when cleared with null',
      () async {
        final _MockWalletFile active = _MockWalletFile();
        when(active.close).thenAnswer((_) async {});
        kWalletFile = active;

        await WalletUtils.setWalletFile(null);

        expect(kWalletFile, isNull);
        verify(active.close).called(1);
      },
    );

    test(
      'setWalletFile still installs next wallet and logs warning if previous '
      'close throws',
      () async {
        final _MockWalletFile previous = _MockWalletFile();
        final _MockWalletFile next = _MockWalletFile();
        when(previous.close).thenThrow(StateError('close failed'));
        when(next.close).thenAnswer((_) async {});

        final List<LogRecord> logs = <LogRecord>[];
        final StreamSubscription<LogRecord> sub = Logger(
          'WalletUtils',
        ).onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        kWalletFile = previous;

        await WalletUtils.setWalletFile(next);

        expect(kWalletFile, same(next));
        verify(previous.close).called(1);
        expect(
          logs.any(
            (LogRecord r) =>
                r.level == Level.WARNING &&
                r.error is StateError &&
                r.error.toString().contains('close failed'),
          ),
          isTrue,
        );
      },
    );

    test(
      'createKeyStoreWalletFile closes previous kWalletFile on success',
      () async {
        final _MockWalletFile previous = _MockWalletFile();
        final _MockKeyStoreWalletFile created = _MockKeyStoreWalletFile();
        when(previous.close).thenAnswer((_) async {});
        when(created.close).thenAnswer((_) async {});
        when(() => created.walletPath).thenReturn('/tmp/new-keystore');

        kWalletFile = previous;
        kWalletPath = '/tmp/old-keystore';
        String? storedPath;

        await WalletUtils.createKeyStoreWalletFile(
          'seed',
          'Pass123!',
          createWalletFile: (_, _, {String? name}) async => created,
          storeWalletPath: (String? path) async {
            storedPath = path;
          },
        );

        expect(storedPath, '/tmp/new-keystore');
        expect(kWalletFile, same(created));
        expect(kWalletPath, '/tmp/new-keystore');
        verify(previous.close).called(1);
        verifyNever(created.close);
      },
    );

    test('createKeyStoreWalletFile closes newly created wallet and preserves '
        'existing kWalletFile when storing wallet path fails', () async {
      final _MockWalletFile previous = _MockWalletFile();
      final _MockKeyStoreWalletFile created = _MockKeyStoreWalletFile();
      when(previous.close).thenAnswer((_) async {});
      when(created.close).thenAnswer((_) async {});
      when(() => created.walletPath).thenReturn('/tmp/new-keystore');

      kWalletFile = previous;
      kWalletPath = '/tmp/old-keystore';

      await expectLater(
        WalletUtils.createKeyStoreWalletFile(
          'seed',
          'Pass123!',
          createWalletFile: (_, _, {String? name}) async => created,
          storeWalletPath: (_) => Future<void>.error(StateError('hive fail')),
        ),
        throwsA(isA<StateError>()),
      );

      expect(kWalletFile, same(previous));
      expect(kWalletPath, '/tmp/old-keystore');
      verify(created.close).called(1);
      verifyNever(previous.close);
    });

    test(
      'createLedgerWalletFile closes previous kWalletFile on success',
      () async {
        final _MockWalletFile previous = _MockWalletFile();
        final _MockLedgerWalletFile created = _MockLedgerWalletFile();
        when(previous.close).thenAnswer((_) async {});
        when(created.close).thenAnswer((_) async {});
        when(() => created.walletPath).thenReturn('/tmp/new-ledger');

        kWalletFile = previous;
        kWalletPath = '/tmp/old-wallet';
        String? storedPath;

        await WalletUtils.createLedgerWalletFile(
          'usb-1',
          'Pass123!',
          walletName: 'Nano X',
          createWalletFile: (_, _, {String? walletName}) async => created,
          storeWalletPath: (String? path) async {
            storedPath = path;
          },
        );

        expect(storedPath, '/tmp/new-ledger');
        expect(kWalletFile, same(created));
        expect(kWalletPath, '/tmp/new-ledger');
        verify(previous.close).called(1);
        verifyNever(created.close);
      },
    );

    test('createLedgerWalletFile closes newly created wallet and preserves '
        'existing kWalletFile when storing wallet path fails', () async {
      final _MockWalletFile previous = _MockWalletFile();
      final _MockLedgerWalletFile created = _MockLedgerWalletFile();
      when(previous.close).thenAnswer((_) async {});
      when(created.close).thenAnswer((_) async {});
      when(() => created.walletPath).thenReturn('/tmp/new-ledger');

      kWalletFile = previous;
      kWalletPath = '/tmp/old-wallet';

      await expectLater(
        WalletUtils.createLedgerWalletFile(
          'usb-1',
          'Pass123!',
          createWalletFile: (_, _, {String? walletName}) async => created,
          storeWalletPath: (_) => Future<void>.error(StateError('hive fail')),
        ),
        throwsA(isA<StateError>()),
      );

      expect(kWalletFile, same(previous));
      expect(kWalletPath, '/tmp/old-wallet');
      verify(created.close).called(1);
      verifyNever(previous.close);
    });
  });
}
