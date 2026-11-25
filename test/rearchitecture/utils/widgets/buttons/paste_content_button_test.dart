import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class _SilentNotificationsBloc extends NotificationsBloc {
  @override
  Future<void> addErrorNotification(Object error, String title) async {}
}

void _setClipboardHandler(Future<Map<String, dynamic>?> Function() responder) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall call,
      ) async {
        if (call.method == 'Clipboard.getData') {
          return await responder();
        }
        return null;
      });
}

void _clearClipboardHandler() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null);
}

void main() {
  tearDown(_clearClipboardHandler);

  group('PasteContentButton', () {
    testWidgets('pastes clipboard text into controller and invokes onPasted', (
      WidgetTester tester,
    ) async {
      _setClipboardHandler(
        () async => <String, dynamic>{'text': 'message to sign'},
      );
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      final List<String> pasted = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasteContentButton(
              controller: controller,
              onPasted: pasted.add,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.content_paste));
      await tester.pump();

      expect(controller.text, 'message to sign');
      expect(pasted, <String>['message to sign']);
    });

    testWidgets('ignores null clipboard response without altering controller', (
      WidgetTester tester,
    ) async {
      sl.registerSingleton<NotificationsBloc>(_SilentNotificationsBloc());
      addTearDown(sl.unregister<NotificationsBloc>);
      _setClipboardHandler(() async => null);

      final TextEditingController controller = TextEditingController(
        text: 'existing',
      );
      addTearDown(controller.dispose);
      final List<String> pasted = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasteContentButton(
              controller: controller,
              onPasted: pasted.add,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.content_paste));
      await tester.pump();

      expect(controller.text, 'existing');
      expect(pasted, isEmpty);
    });

    testWidgets('ignores empty string clipboard without altering controller', (
      WidgetTester tester,
    ) async {
      sl.registerSingleton<NotificationsBloc>(_SilentNotificationsBloc());
      addTearDown(sl.unregister<NotificationsBloc>);
      _setClipboardHandler(() async => <String, dynamic>{'text': ''});

      final TextEditingController controller = TextEditingController(
        text: 'keep',
      );
      addTearDown(controller.dispose);
      final List<String> pasted = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasteContentButton(
              controller: controller,
              onPasted: pasted.add,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.content_paste));
      await tester.pump();

      expect(controller.text, 'keep');
      expect(pasted, isEmpty);
    });

    testWidgets('ignores late clipboard reply after widget is disposed', (
      WidgetTester tester,
    ) async {
      final Completer<Map<String, dynamic>?> completer =
          Completer<Map<String, dynamic>?>();
      _setClipboardHandler(() => completer.future);

      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      final List<String> pasted = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasteContentButton(
              controller: controller,
              onPasted: pasted.add,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.content_paste));
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      completer.complete(<String, dynamic>{'text': 'late value'});
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(pasted, isEmpty);
    });
  });
}
