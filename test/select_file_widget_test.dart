import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/select_file_widget.dart';

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
}
