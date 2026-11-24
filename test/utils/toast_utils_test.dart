import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';

void main() {
  testWidgets('replaces the current toast with the latest message', (
    WidgetTester tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    ToastUtils.showToast(context, 'First message');
    await tester.pump();
    expect(find.text('First message'), findsOneWidget);

    ToastUtils.showToast(context, 'Second message');
    await tester.pump();
    expect(find.text('First message'), findsNothing);
    expect(find.text('Second message'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Second message'), findsNothing);
  });
}
