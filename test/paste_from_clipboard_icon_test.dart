import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/paste_from_clipboard_icon.dart';

void _setClipboardText(String? text) {
  // Clipboard.getData is handled by the platform channel in production;
  // tests answer it with a mock handler.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform,
          (MethodCall call) async {
    if (call.method == 'Clipboard.getData') {
      // A null result models an empty clipboard.
      return text == null ? null : <String, dynamic>{'text': text};
    }
    return null;
  });
}

/// The empty-clipboard path surfaces an in-app error notification, whose
/// storage does real file IO — that cannot complete inside a widget
/// test's fake-async zone, so the notification is swallowed here.
class _SilentNotificationsBloc extends NotificationsBloc {
  @override
  Future<void> addErrorNotification(Object error, String title) async {}
}

void main() {
  testWidgets('tapping the icon pastes the clipboard text', (tester) async {
    _setClipboardText('message to sign');
    addTearDown(() => _setClipboardText(null));
    final pasted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasteFromClipboardIcon(onValue: pasted.add),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.content_paste));
    await tester.pump();

    expect(pasted, ['message to sign']);
  });

  testWidgets('an empty clipboard delivers no value', (tester) async {
    sl.registerSingleton<NotificationsBloc>(_SilentNotificationsBloc());
    addTearDown(sl.unregister<NotificationsBloc>);
    _setClipboardText(null);
    addTearDown(() => _setClipboardText(null));
    final pasted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasteFromClipboardIcon(onValue: pasted.add),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.content_paste));
    await tester.pump();

    expect(pasted, isEmpty);
  });
}
