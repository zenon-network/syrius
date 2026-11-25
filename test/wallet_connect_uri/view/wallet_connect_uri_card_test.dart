import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class _MockWeb3WalletService extends Mock implements IWeb3WalletService {}

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

class _MockHydratedStorage extends Mock implements Storage {}

PairingInfo _buildPairing(String topic) => PairingInfo(
  topic: topic,
  expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
  active: false,
);

void main() {
  const String validUriA =
      'wc:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@2'
      '?relay-protocol=irn&symKey='
      '1111111111111111111111111111111111111111111111111111111111111111';
  const String validUriB =
      'wc:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb@2'
      '?relay-protocol=irn&symKey='
      '2222222222222222222222222222222222222222222222222222222222222222';

  late _MockWeb3WalletService web3WalletService;
  late _MockSharedPrefsService mockSharedPrefs;
  late _MockHydratedStorage mockHydratedStorage;
  SharedPrefsService? previousSharedPrefs;

  setUpAll(() {
    registerFallbackValue(Uri.parse(validUriA));
  });

  setUp(() async {
    await sl.reset();
    mockHydratedStorage = _MockHydratedStorage();
    when(() => mockHydratedStorage.read(any())).thenReturn(null);
    when(
      () => mockHydratedStorage.write(any(), any<dynamic>()),
    ).thenAnswer((_) async {});
    when(() => mockHydratedStorage.delete(any())).thenAnswer((_) async {});
    when(() => mockHydratedStorage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = mockHydratedStorage;

    previousSharedPrefs = sharedPrefsService;
    mockSharedPrefs = _MockSharedPrefsService();
    when(
      () =>
          mockSharedPrefs.get(any(), defaultValue: any(named: 'defaultValue')),
    ).thenAnswer(
      (Invocation invocation) => invocation.namedArguments[#defaultValue],
    );
    sharedPrefsService = mockSharedPrefs;
    kLastWalletConnectUriNotifier.value = null;
    web3WalletService = _MockWeb3WalletService();
    sl.registerSingleton<IWeb3WalletService>(web3WalletService);
  });

  tearDown(() async {
    kLastWalletConnectUriNotifier.value = null;
    sharedPrefsService = previousSharedPrefs;
    await sl.reset();
  });

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 400,
            child: WalletConnectUriCard(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'clears pre-populated initial URI cleanly after pairing succeeds without '
    'repopulating initialValue or showing validation error',
    (WidgetTester tester) async {
      kLastWalletConnectUriNotifier.value = validUriA;
      when(
        () => web3WalletService.pair(any()),
      ).thenAnswer((_) async => _buildPairing('topic-a'));

      await pumpCard(tester);

      final TextFormField field = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(field.controller?.text, validUriA);

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(field.controller?.text, isEmpty);
      expect(find.text('URI is invalid'), findsNothing);
    },
  );

  testWidgets(
    'preserves newer user-edited input when an earlier in-flight pairing '
    'succeeds',
    (WidgetTester tester) async {
      final Completer<PairingInfo> pairCompleter = Completer<PairingInfo>();
      when(
        () => web3WalletService.pair(any()),
      ).thenAnswer((_) => pairCompleter.future);

      await pumpCard(tester);

      await tester.enterText(find.byType(TextFormField), validUriA);
      await tester.pump();
      await tester.tap(find.text('Connect'));
      await tester.pump();

      // User replaces the field with a newer URI while pairing A is pending.
      await tester.enterText(find.byType(TextFormField), validUriB);
      await tester.pump();

      pairCompleter.complete(_buildPairing('topic-a'));
      await tester.pumpAndSettle();

      final TextFormField field = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(field.controller?.text, validUriB);
    },
  );

  testWidgets(
    'preserves newer external URI delivered via notifier while an earlier '
    'pairing is in flight',
    (WidgetTester tester) async {
      final Completer<PairingInfo> pairCompleter = Completer<PairingInfo>();
      when(
        () => web3WalletService.pair(any()),
      ).thenAnswer((_) => pairCompleter.future);

      await pumpCard(tester);

      await tester.enterText(find.byType(TextFormField), validUriA);
      await tester.pump();
      await tester.tap(find.text('Connect'));
      await tester.pump();

      // External clipboard/deep-link delivers URI B while pairing A is pending.
      kLastWalletConnectUriNotifier.value = validUriB;
      await tester.pump();

      pairCompleter.complete(_buildPairing('topic-a'));
      await tester.pumpAndSettle();

      final TextFormField field = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(field.controller?.text, validUriB);
    },
  );
}
