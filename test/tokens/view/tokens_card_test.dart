import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}

class MockMultipleBalanceBloc
    extends MockBloc<MultipleBalanceEvent, MultipleBalanceState>
    implements MultipleBalanceBloc {}

class MockNotificationsBloc extends Mock implements NotificationsBloc {}

class MockSharedPrefsService extends Mock implements SharedPrefsService {}

class FakeWalletNotification extends Fake implements WalletNotification {}

Token _buildToken({
  required String name,
  required String symbol,
  required String owner,
  required int seedByte,
}) => Token(
  name,
  symbol,
  'zenon.org',
  BigInt.from(85),
  0,
  Address.parse(owner),
  TokenStandard.fromBytes(List<int>.filled(TokenStandard.coreSize, seedByte)),
  BigInt.from(100),
  false,
  false,
  true,
);

void main() {
  initHydratedStorage();

  const String walletOwner = 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d';
  const String otherOwner = 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e';

  late Box<dynamic> favoriteTokensBox;
  late MockZenon mockZenon;
  late MockWsClient mockWsClient;
  late MockEmbedded mockEmbedded;
  late MockTokenApi mockTokenApi;
  late MockMultipleBalanceBloc multipleBalanceBloc;
  late MockNotificationsBloc notificationsBloc;
  late MockSharedPrefsService mockSharedPrefsService;
  late Zenon? previousZenon;
  late SharedPrefsService? previousSharedPrefsService;

  setUpAll(() {
    registerFallbackValue(FakeWalletNotification());
  });

  setUp(() async {
    favoriteTokensBox = await Hive.openBox<dynamic>(
      kFavoriteTokensBox,
      bytes: Uint8List(0),
    );

    mockZenon = MockZenon();
    mockWsClient = MockWsClient();
    mockEmbedded = MockEmbedded();
    mockTokenApi = MockTokenApi();
    multipleBalanceBloc = MockMultipleBalanceBloc();
    notificationsBloc = MockNotificationsBloc();
    mockSharedPrefsService = MockSharedPrefsService();

    when(() => mockZenon.wsClient).thenReturn(mockWsClient);
    when(
      () => mockWsClient.restartedStream,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(() => mockZenon.embedded).thenReturn(mockEmbedded);
    when(() => mockEmbedded.token).thenReturn(mockTokenApi);
    when(
      () => multipleBalanceBloc.state,
    ).thenReturn(const MultipleBalanceState());
    when(
      () => notificationsBloc.addNotification(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockSharedPrefsService.get(
        any<String>(),
        defaultValue: any<dynamic>(named: 'defaultValue'),
      ),
    ).thenReturn(false);

    previousZenon = app.zenon;
    previousSharedPrefsService = app.sharedPrefsService;
    app.zenon = mockZenon;
    app.sharedPrefsService = mockSharedPrefsService;

    if (app.sl.isRegistered<NotificationsBloc>()) {
      await app.sl.unregister<NotificationsBloc>();
    }
    app.sl.registerSingleton<NotificationsBloc>(notificationsBloc);

    kSelectedAddress = walletOwner;
    kDefaultAddressList = <String?>[walletOwner];
    kAddressLabelMap = <String, String>{walletOwner: 'Wallet 1'};
  });

  tearDown(() async {
    await multipleBalanceBloc.close();
    await Hive.close();
    app.zenon = previousZenon;
    app.sharedPrefsService = previousSharedPrefsService;
    if (app.sl.isRegistered<NotificationsBloc>()) {
      await app.sl.unregister<NotificationsBloc>();
    }
    kSelectedAddress = null;
    kDefaultAddressList = <String?>[];
    kAddressLabelMap = <String, String>{};
  });

  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
  }

  Future<void> pumpTokensCard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BlocProvider<MultipleBalanceBloc>.value(
        value: multipleBalanceBloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(width: 1500, height: 1100, child: TokensCard()),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
  }

  List<String> visibleTokenNamesInOrder(WidgetTester tester) {
    final Iterable<Element> cardElements = find.byType(TokenCard).evaluate();
    final List<({Offset offset, String name})> entries =
        <({Offset offset, String name})>[];
    for (final Element element in cardElements) {
      final RenderBox box = element.renderObject! as RenderBox;
      final Offset topLeft = box.localToGlobal(Offset.zero);
      final Finder textFinder = find.descendant(
        of: find.byElementPredicate((Element e) => identical(e, element)),
        matching: find.byType(Text),
      );
      final String name = tester.widget<Text>(textFinder.first).data!;
      entries.add((offset: topLeft, name: name));
    }
    entries.sort((
      ({Offset offset, String name}) a,
      ({Offset offset, String name}) b,
    ) {
      final int dy = a.offset.dy.compareTo(b.offset.dy);
      return dy != 0 ? dy : a.offset.dx.compareTo(b.offset.dx);
    });
    return entries.map((({Offset offset, String name}) e) => e.name).toList();
  }

  group('TokensCard', () {
    testWidgets(
      'excludes native coins and preserves RPC order without reordering '
      'owned or favorite tokens',
      (WidgetTester tester) async {
        final Token regularToken = _buildToken(
          name: 'First Regular',
          symbol: 'REG1',
          owner: otherOwner,
          seedByte: 1,
        );
        final Token ownedToken = _buildToken(
          name: 'Second Owned',
          symbol: 'OWN2',
          owner: walletOwner,
          seedByte: 2,
        );
        final Token favoriteToken = _buildToken(
          name: 'Third Favorite',
          symbol: 'FAV3',
          owner: otherOwner,
          seedByte: 3,
        );
        await favoriteTokensBox.add(favoriteToken.tokenStandard.toString());

        when(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => TokenList(
            count: 5,
            list: <Token>[
              kZnnCoin,
              kQsrCoin,
              regularToken,
              ownedToken,
              favoriteToken,
            ],
          ),
        );

        await pumpTokensCard(tester);

        expect(visibleTokenNamesInOrder(tester), <String>[
          'First Regular',
          'Second Owned',
          'Third Favorite',
        ]);
        expect(find.text(kZnnCoin.name), findsNothing);
        expect(find.text(kQsrCoin.name), findsNothing);
      },
    );

    testWidgets(
      'appends later pages in order and toggles favorites without resetting '
      'loaded pages',
      (WidgetTester tester) async {
        final List<Token> page0Zts = List<Token>.generate(
          kPageSize - 2,
          (int index) => _buildToken(
            name: 'Page0 Token $index',
            symbol: 'P0T$index',
            owner: otherOwner,
            seedByte: index + 10,
          ),
        );
        final List<Token> page0 = <Token>[kZnnCoin, kQsrCoin, ...page0Zts];
        final Token page1OwnedFavorite = _buildToken(
          name: 'Page1 Owned Favorite',
          symbol: 'P1OF',
          owner: walletOwner,
          seedByte: 99,
        );
        await favoriteTokensBox.add(
          page1OwnedFavorite.tokenStandard.toString(),
        );

        when(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final int pageIndex = invocation.namedArguments[#pageIndex]! as int;
          if (pageIndex == 0) {
            return TokenList(count: kPageSize + 1, list: page0);
          }
          return TokenList(
            count: kPageSize + 1,
            list: <Token>[page1OwnedFavorite],
          );
        });

        await pumpTokensCard(tester);

        // Request the next page and ensure earlier page items stay first.
        final BuildContext gridContext = tester.element(
          find.byType(InfiniteScrollGrid<Token>),
        );
        gridContext.read<TokensBloc>().add(const InfiniteListMoreRequested());
        await pumpFrames(tester);

        final InfiniteScrollGrid<Token> grid = tester.widget(
          find.byType(InfiniteScrollGrid<Token>),
        );
        expect(grid.items.map((Token t) => t.name).toList(), <String>[
          ...page0Zts.map((Token t) => t.name),
          'Page1 Owned Favorite',
        ]);
        verify(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).called(2);

        // Toggle favorite on the first visible token and verify it updates in
        // place without refreshing or discarding page 1.
        await tester.tap(find.byIcon(Icons.star_border).first);
        await pumpFrames(tester);

        expect(
          favoriteTokensBox.values,
          contains(page0Zts.first.tokenStandard.toString()),
        );
        verifyNever(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        );
        final InfiniteScrollGrid<Token> gridAfterFavorite = tester.widget(
          find.byType(InfiniteScrollGrid<Token>),
        );
        expect(gridAfterFavorite.items, hasLength(page0Zts.length + 1));
        expect(gridAfterFavorite.items.last.name, 'Page1 Owned Favorite');
      },
    );

    testWidgets(
      'toggling a favorite in search results preserves order and does not '
      're-fetch tokens',
      (WidgetTester tester) async {
        final Token firstMatch = _buildToken(
          name: 'Alpha First',
          symbol: 'ALP1',
          owner: otherOwner,
          seedByte: 11,
        );
        final Token secondMatch = _buildToken(
          name: 'Alpha Second',
          symbol: 'ALP2',
          owner: walletOwner,
          seedByte: 12,
        );

        when(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async =>
              TokenList(count: 2, list: <Token>[firstMatch, secondMatch]),
        );

        await pumpTokensCard(tester);
        clearInteractions(mockTokenApi);

        await tester.enterText(find.byType(TextField), 'Alpha');
        await tester.pump(const Duration(milliseconds: 400));
        await pumpFrames(tester);

        expect(visibleTokenNamesInOrder(tester), <String>[
          'Alpha First',
          'Alpha Second',
        ]);
        verify(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);

        await tester.tap(find.byIcon(Icons.star_border).last);
        await pumpFrames(tester);

        expect(
          favoriteTokensBox.values,
          contains(secondMatch.tokenStandard.toString()),
        );
        verifyNever(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        );
        expect(visibleTokenNamesInOrder(tester), <String>[
          'Alpha First',
          'Alpha Second',
        ]);
      },
    );
  });
}
