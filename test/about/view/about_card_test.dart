import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app_main;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/about/about.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart' as app_global;
import 'package:zenon_syrius_wallet_flutter/utils/metadata.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class _MockAboutBloc extends MockBloc<AboutEvent, AboutState>
    implements AboutBloc {}

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

class _MockMomentum extends Mock implements Momentum {}

class _MockProcessInfo extends Mock implements ProcessInfo {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _MockOsInfo extends Mock implements OsInfo {}

void main() {
  late _MockAboutBloc mockBloc;
  late _MockSharedPrefsService mockSharedPrefsService;
  SharedPrefsService? previousSharedPrefsService;
  String? previousLocalIpAddress;

  setUpAll(() {
    initHydratedStorage();
    registerFallbackValue(const AboutRequested());
  });

  setUp(() {
    mockBloc = _MockAboutBloc();
    mockSharedPrefsService = _MockSharedPrefsService();
    when(
      () => mockSharedPrefsService.get(
        any(),
        defaultValue: any<dynamic>(named: 'defaultValue'),
      ),
    ).thenReturn(false);

    previousSharedPrefsService = app_main.sharedPrefsService;
    previousLocalIpAddress = app_global.kLocalIpAddress;
    app_main.sharedPrefsService = mockSharedPrefsService;
    app_global.kLocalIpAddress = null;
  });

  tearDown(() {
    app_main.sharedPrefsService = previousSharedPrefsService;
    app_global.kLocalIpAddress = previousLocalIpAddress;
  });

  Widget buildSubject({
    Future<void> Function(String path)? onOpenPath,
    void Function(String url)? onOpenUrl,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 900,
          height: 700,
          child: AboutCard(
            bloc: mockBloc,
            onOpenPath: onOpenPath,
            onOpenUrl: onOpenUrl,
          ),
        ),
      ),
    );
  }

  GeneralStats createStats() {
    final _MockMomentum momentum = _MockMomentum();
    final _MockProcessInfo processInfo = _MockProcessInfo();
    final _MockNetworkInfo networkInfo = _MockNetworkInfo();
    final _MockOsInfo osInfo = _MockOsInfo();

    when(() => momentum.chainIdentifier).thenReturn(1);
    when(() => processInfo.version).thenReturn('0.0.7');
    when(() => processInfo.commit).thenReturn('abcdef1234');
    when(() => osInfo.kernelVersion).thenReturn('6.8.0');
    when(() => osInfo.os).thenReturn('linux');
    when(() => osInfo.platform).thenReturn('ubuntu');
    when(() => osInfo.platformVersion).thenReturn('24.04');
    when(() => osInfo.numCPU).thenReturn(8);

    return GeneralStats(
      frontierMomentum: momentum,
      processInfo: processInfo,
      networkInfo: networkInfo,
      osInfo: osInfo,
    );
  }

  group('AboutCard', () {
    testWidgets('shows loading widget while AboutLoading', (
      WidgetTester tester,
    ) async {
      whenListen<AboutState>(
        mockBloc,
        const Stream<AboutState>.empty(),
        initialState: const AboutLoading(),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('About'), findsAtLeastNWidgets(1));
      expect(find.byType(SyriusLoadingWidget), findsOneWidget);
    });

    testWidgets('shows error widget on AboutFailure and refreshes on tap', (
      WidgetTester tester,
    ) async {
      whenListen<AboutState>(
        mockBloc,
        const Stream<AboutState>.empty(),
        initialState: AboutFailure(exception: FailureException()),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.byType(SyriusErrorWidget), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh).first);
      await tester.pump();

      verify(() => mockBloc.add(const AboutRequested())).called(1);
    });

    testWidgets(
      'renders populated metadata safely and invokes path/url callbacks',
      (WidgetTester tester) async {
        final List<String> openedPaths = <String>[];
        final List<String> openedUrls = <String>[];

        whenListen<AboutState>(
          mockBloc,
          const Stream<AboutState>.empty(),
          initialState: AboutPopulated(stats: createStats()),
        );

        await tester.pumpWidget(
          buildSubject(
            onOpenPath: (String path) async => openedPaths.add(path),
            onOpenUrl: openedUrls.add,
          ),
        );

        expect(find.text('About'), findsAtLeastNWidgets(1));
        expect(find.text('Syrius wallet version'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Syrius git origin url'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Syrius git origin url'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.link));
        await tester.pump();
        expect(openedUrls, equals(<String>[gitOriginUrl]));

        await tester.scrollUntilVisible(
          find.text('Zenon main data path'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Zenon main data path'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.open_in_new).first);
        await tester.pump();
        expect(
          openedPaths,
          equals(<String>[znnDefaultPaths.main.absolute.path]),
        );

        await tester.scrollUntilVisible(
          find.text('Syrius wallet type'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Syrius wallet type'));
        await tester.pumpAndSettle();

        // Wallet type is rendered as text (with '-' fallback when null), not
        // as an openable file path.
        final Finder walletTypePanel = find.ancestor(
          of: find.text('Syrius wallet type'),
          matching: find.byType(CustomExpandablePanel),
        );
        expect(
          find.descendant(
            of: walletTypePanel,
            matching: find.byIcon(Icons.open_in_new),
          ),
          findsNothing,
        );
      },
    );
  });
}
