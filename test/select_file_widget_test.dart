import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/select_file_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void _dropFile(WidgetTester tester, String path) {
  final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));
  dropTarget.onDragDone!(
    DropDoneDetails(
      files: [DropItemFile(path)],
      localPosition: Offset.zero,
      globalPosition: Offset.zero,
    ),
  );
}

Future<void> _pumpWidget(
  WidgetTester tester,
  void Function(String) onPathFound,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectFileWidget(
          fileExtension: 'json',
          onPathFoundCallback: onPathFound,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a dropped keystore without .json extension is accepted',
      (WidgetTester tester) async {
    final foundPaths = <String>[];
    await _pumpWidget(tester, foundPaths.add);

    _dropFile(tester, '/home/user/wallet.bak');

    expect(foundPaths, ['/home/user/wallet.bak']);
  });

  testWidgets('a dropped file with .json extension is still accepted',
      (WidgetTester tester) async {
    final foundPaths = <String>[];
    await _pumpWidget(tester, foundPaths.add);

    _dropFile(tester, '/home/user/wallet.json');

    expect(foundPaths, ['/home/user/wallet.json']);
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
      final oversized = File('${tempDir.path}/huge.json')
        ..writeAsStringSync('x' * (WalletFile.maxWalletFileSizeBytes + 1));

      expect(
        () => WalletFile.read(oversized.path),
        throwsA(isA<WalletException>()),
      );
    });

    test('reaches parsing for a file within the limit', () async {
      // Not valid keystore JSON — the guard must let it through to the
      // parser, which rejects it with a FormatException instead.
      final small = File('${tempDir.path}/small.json')
        ..writeAsStringSync('not json');

      expect(
        () => WalletFile.read(small.path),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
