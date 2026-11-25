import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/select_file_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void _dropFiles(WidgetTester tester, List<String> paths) {
  final DropTarget dropTarget = tester.widget<DropTarget>(
    find.byType(DropTarget),
  );
  dropTarget.onDragDone!(
    DropDoneDetails(
      files: paths.map<DropItem>(DropItemFile.new).toList(),
      localPosition: Offset.zero,
      globalPosition: Offset.zero,
    ),
  );
}

Future<void> _pumpWidget(
  WidgetTester tester,
  void Function(String) onPathFound, {
  String? fileExtension = 'json',
  GlobalKey<SelectFileWidgetState>? widgetKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectFileWidget(
          key: widgetKey,
          fileExtension: fileExtension,
          onPathFoundCallback: onPathFound,
        ),
      ),
    ),
  );
}

void main() {
  group('SelectFileWidget', () {
    testWidgets('accepts a dropped keystore without .json extension', (
      WidgetTester tester,
    ) async {
      final List<String> foundPaths = <String>[];
      await _pumpWidget(tester, foundPaths.add);

      _dropFiles(tester, <String>['/home/user/wallet.bak']);
      await tester.pump();

      expect(foundPaths, <String>['/home/user/wallet.bak']);
      expect(find.text('/home/user/wallet.bak'), findsOneWidget);
    });

    testWidgets('accepts a dropped extensionless keystore file', (
      WidgetTester tester,
    ) async {
      final List<String> foundPaths = <String>[];
      await _pumpWidget(tester, foundPaths.add);

      _dropFiles(tester, <String>['/home/user/wallet']);
      await tester.pump();

      expect(foundPaths, <String>['/home/user/wallet']);
      expect(find.text('/home/user/wallet'), findsOneWidget);
    });

    testWidgets('still accepts a dropped file with .json extension', (
      WidgetTester tester,
    ) async {
      final List<String> foundPaths = <String>[];
      await _pumpWidget(tester, foundPaths.add);

      _dropFiles(tester, <String>['/home/user/wallet.json']);
      await tester.pump();

      expect(foundPaths, <String>['/home/user/wallet.json']);
      expect(find.text('/home/user/wallet.json'), findsOneWidget);
    });

    testWidgets(
      'accepts dropped files when fileExtension is null and resets message',
      (WidgetTester tester) async {
        final GlobalKey<SelectFileWidgetState> key =
            GlobalKey<SelectFileWidgetState>();
        final List<String> foundPaths = <String>[];
        await _pumpWidget(
          tester,
          foundPaths.add,
          fileExtension: null,
          widgetKey: key,
        );

        _dropFiles(tester, <String>['/home/user/document.bin']);
        await tester.pump();

        expect(foundPaths, <String>['/home/user/document.bin']);
        expect(find.text('/home/user/document.bin'), findsOneWidget);

        key.currentState!.resetMessageToUser();
        await tester.pump();

        expect(find.text('/home/user/document.bin'), findsNothing);
      },
    );

    testWidgets('ignores an empty drop payload without throwing', (
      WidgetTester tester,
    ) async {
      final List<String> foundPaths = <String>[];
      await _pumpWidget(tester, foundPaths.add);

      _dropFiles(tester, <String>[]);
      await tester.pump();

      expect(foundPaths, isEmpty);
    });
  });

  group('WalletFile.read size guard', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wallet-file-test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('rejects a file above the keystore size limit', () async {
      final File oversized = File('${tempDir.path}/huge.json')
        ..writeAsStringSync('x' * (WalletFile.maxWalletFileSizeBytes + 1));

      await expectLater(
        () => WalletFile.read(oversized.path),
        throwsA(isA<WalletException>()),
      );
    });

    test('accepts a file exactly at the limit into the parser', () async {
      // Exactly maxWalletFileSizeBytes bytes: the bounded read must not
      // reject it, so the parser is reached and fails on the content.
      final File exact = File('${tempDir.path}/exact.json')
        ..writeAsStringSync('x' * WalletFile.maxWalletFileSizeBytes);

      await expectLater(
        () => WalletFile.read(exact.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('reaches parsing for a file within the limit', () async {
      // Not valid keystore JSON — the guard must let it through to the
      // parser, which rejects it with a FormatException instead.
      final File small = File('${tempDir.path}/small.json')
        ..writeAsStringSync('not json');

      await expectLater(
        () => WalletFile.read(small.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws WalletException when file does not exist', () async {
      await expectLater(
        () => WalletFile.read('${tempDir.path}/missing.json'),
        throwsA(isA<WalletException>()),
      );
    });

    test('throws FormatException for non-object JSON within limit', () async {
      final File arrayJson = File('${tempDir.path}/array.json')
        ..writeAsStringSync('[1, 2, 3]');

      await expectLater(
        () => WalletFile.read(arrayJson.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for non-UTF-8 binary data', () async {
      final File binary = File('${tempDir.path}/binary.dat')
        ..writeAsBytesSync(<int>[0xFF, 0xFE, 0x00, 0x01]);

      await expectLater(
        () => WalletFile.read(binary.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('reads a valid encrypted wallet file within the size limit', () async {
      final String walletPath = '${tempDir.path}/valid_keystore';
      final EncryptedFile encrypted = await EncryptedFile.encrypt(
        utf8.encode('test-entropy-data'),
        'TestPass123!',
      );
      File(walletPath).writeAsStringSync(json.encode(encrypted));

      final EncryptedFile loaded = await WalletFile.read(walletPath);
      final List<int> decrypted = await loaded.decrypt('TestPass123!');

      expect(utf8.decode(decrypted), 'test-entropy-data');
    });
  });
}
