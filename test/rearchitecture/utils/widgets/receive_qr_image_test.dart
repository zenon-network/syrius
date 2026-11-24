import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/receive_qr_image.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  testWidgets('replaces the QR render object when data changes', (
    WidgetTester tester,
  ) async {
    const String firstData = 'znn:first-address';
    const String secondData = 'znn:second-address';

    await tester.pumpWidget(const _TestApp(data: firstData));
    final RenderObject firstRenderObject = tester.renderObject(
      find.byType(PrettyQrView),
    );

    await tester.pumpWidget(const _TestApp(data: secondData));
    final RenderObject secondRenderObject = tester.renderObject(
      find.byType(PrettyQrView),
    );

    expect(secondRenderObject, isNot(same(firstRenderObject)));
    expect(
      tester.widget<PrettyQrView>(find.byType(PrettyQrView)).key,
      const ValueKey<String>(secondData),
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ReceiveQrImage(
          data: data,
          size: 150,
          tokenStandard: znnZts,
        ),
      ),
    );
  }
}
