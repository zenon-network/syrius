import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/paste_from_clipboard_icon.dart';

Future<void> _setClipboardText(String text) async {
  // Clipboard.getData is handled by the platform channel in production;
  // tests answer it with a mock handler.
  SystemChannels.platform.setMockMethodCallHandler((MethodCall call) async {
    if (call.method == 'Clipboard.getData') {
      return <String, dynamic>{'text': text};
    }
    return null;
  });
}

void main() {
  testWidgets('tapping the icon pastes the clipboard text', (tester) async {
    await _setClipboardText('message to sign');
    final pasted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasteFromClipboardIcon(onValue: pasted.add),
        ),
      ),
    );
    addTearDown(() => SystemChannels.platform.setMockMethodCallHandler(null));

    await tester.tap(find.byIcon(Icons.content_paste));
    await tester.pump();

    expect(pasted, ['message to sign']);
  });
}
