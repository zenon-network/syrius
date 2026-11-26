import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/token_favorite/token_favorite.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

class _FakeWalletNotification extends Fake implements WalletNotification {}

Token _buildToken() => Token(
  'Sample Token',
  'SMP',
  'zenon.org',
  BigInt.from(100),
  0,
  Address.parse('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d'),
  TokenStandard.fromBytes(List<int>.filled(TokenStandard.coreSize, 7)),
  BigInt.from(1000),
  false,
  false,
  true,
);

void main() {
  late Box<dynamic> favoriteTokensBox;
  late _MockNotificationsBloc notificationsBloc;

  setUpAll(() {
    registerFallbackValue(_FakeWalletNotification());
  });

  setUp(() async {
    favoriteTokensBox = await Hive.openBox<dynamic>(
      kFavoriteTokensBox,
      bytes: Uint8List(0),
    );
    notificationsBloc = _MockNotificationsBloc();
    when(
      () => notificationsBloc.addNotification(any()),
    ).thenAnswer((_) async {});

    if (app.sl.isRegistered<NotificationsBloc>()) {
      await app.sl.unregister<NotificationsBloc>();
    }
    app.sl.registerSingleton<NotificationsBloc>(notificationsBloc);
  });

  tearDown(() async {
    await Hive.close();
    if (app.sl.isRegistered<NotificationsBloc>()) {
      await app.sl.unregister<NotificationsBloc>();
    }
  });

  Widget buildSubject({required Token token, VoidCallback? callback}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TokenFavorite(token: token, callback: callback),
      ),
    );
  }

  group('TokenFavorite', () {
    testWidgets('toggles add and remove without a callback', (
      WidgetTester tester,
    ) async {
      final Token token = _buildToken();
      await tester.pumpWidget(buildSubject(token: token));
      await tester.pump();

      expect(find.byIcon(Icons.star_border), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(
        favoriteTokensBox.values,
        contains(token.tokenStandard.toString()),
      );

      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(
        favoriteTokensBox.values,
        isNot(contains(token.tokenStandard.toString())),
      );
      verify(() => notificationsBloc.addNotification(any())).called(2);
    });

    testWidgets('invokes optional callback on add and remove when provided', (
      WidgetTester tester,
    ) async {
      final Token token = _buildToken();
      int callbackCount = 0;

      await tester.pumpWidget(
        buildSubject(token: token, callback: () => callbackCount++),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();
      expect(callbackCount, 1);

      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();
      expect(callbackCount, 2);
    });
  });
}
