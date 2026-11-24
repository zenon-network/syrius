import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/base_modal.dart';

void main() {
  group('BaseModal', () {
    testWidgets('exposes localized close button tooltip and pops on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => const Dialog(
                      child: BaseModal(
                        title: 'Test Modal',
                        child: Text('Modal Content'),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test Modal'), findsOneWidget);
      expect(find.text('Modal Content'), findsOneWidget);

      final BuildContext modalContext = tester.element(find.byType(BaseModal));
      final String expectedTooltip = MaterialLocalizations.of(
        modalContext,
      ).closeButtonTooltip;

      final Finder closeButtonFinder = find.byTooltip(expectedTooltip);
      expect(closeButtonFinder, findsOneWidget);

      await tester.tap(closeButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(BaseModal), findsNothing);
    });
  });
}
