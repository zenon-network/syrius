import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app_main;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/refresh_button/refresh_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../../helpers/hydrated_bloc.dart';

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

class _MockZenon extends Mock implements Zenon {}

class _TestLoadingCubit extends Cubit<bool> {
  _TestLoadingCubit({required bool initialState}) : super(initialState);

  void setLoading({required bool isLoading}) => emit(isLoading);
}

class _TestFetchBloc extends FetchBloc<String> {
  _TestFetchBloc({required super.zenon, required this._fetchHandler})
    : super(
        fromJsonT: (Map<String, dynamic> json) => json['v'] as String,
        toJsonT: (String value) => <String, dynamic>{'v': value},
      );

  final Future<String> Function(Address address) _fetchHandler;

  @override
  Future<String> getData({required Address address}) => _fetchHandler(address);
}

void main() {
  initHydratedStorage();

  group('CardScaffoldHeader refresh loading integration', () {
    testWidgets(
      'forwards isRefreshLoading to RefreshButton and disables tap while '
      'loading',
      (WidgetTester tester) async {
        int refreshCount = 0;
        final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
        addTearDown(isLoading.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CardScaffoldHeader(
                title: 'Sample Card',
                onMoreIconPressed: () {},
                onRefreshPressed: () => refreshCount++,
                isRefreshLoading: isLoading,
              ),
            ),
          ),
        );

        final Finder refreshButton = find.byType(RefreshButton);
        expect(refreshButton, findsOneWidget);
        expect(
          find.descendant(
            of: refreshButton,
            matching: find.byIcon(Icons.refresh),
          ),
          findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.refresh));
        expect(refreshCount, 1);

        isLoading.value = true;
        await tester.pump();

        expect(
          find.descendant(
            of: refreshButton,
            matching: find.byType(SyriusLoadingWidget),
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<IconButton>(
                find.descendant(
                  of: refreshButton,
                  matching: find.byType(IconButton),
                ),
              )
              .onPressed,
          isNull,
        );

        await tester.tap(
          find.descendant(
            of: refreshButton,
            matching: find.byType(IconButton),
          ),
        );
        expect(refreshCount, 1);

        isLoading.value = false;
        await tester.pump();

        expect(
          find.descendant(
            of: refreshButton,
            matching: find.byIcon(Icons.refresh),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byIcon(Icons.refresh));
        expect(refreshCount, 2);
      },
    );
  });

  group('NewCardScaffold refresh loading integration', () {
    late _MockSharedPrefsService mockSharedPrefsService;
    SharedPrefsService? previousSharedPrefsService;

    setUp(() {
      mockSharedPrefsService = _MockSharedPrefsService();
      when(
        () => mockSharedPrefsService.get(
          any(),
          defaultValue: any<dynamic>(named: 'defaultValue'),
        ),
      ).thenReturn(false);

      previousSharedPrefsService = app_main.sharedPrefsService;
      app_main.sharedPrefsService = mockSharedPrefsService;
    });

    tearDown(() {
      app_main.sharedPrefsService = previousSharedPrefsService;
    });

    testWidgets(
      'forwards isRefreshLoading to front and back CardScaffoldHeader '
      'RefreshButtons',
      (WidgetTester tester) async {
        int refreshCount = 0;
        final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
        addTearDown(isLoading.dispose);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: NewCardScaffold(
                  data: CardData(
                    title: 'Test Card',
                    description: 'Test description',
                  ),
                  isRefreshLoading: isLoading,
                  onRefreshPressed: () => refreshCount++,
                  body: const Center(child: Text('Body')),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RefreshButton), findsNWidgets(2));
        expect(
          find.descendant(
            of: find.byType(RefreshButton),
            matching: find.byIcon(Icons.refresh),
          ),
          findsNWidgets(2),
        );

        await tester.tap(find.byIcon(Icons.refresh).first);
        expect(refreshCount, 1);

        isLoading.value = true;
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(RefreshButton),
            matching: find.byType(SyriusLoadingWidget),
          ),
          findsNWidgets(2),
        );
        expect(
          find.descendant(
            of: find.byType(RefreshButton),
            matching: find.byIcon(Icons.refresh),
          ),
          findsNothing,
        );

        isLoading.value = false;
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(RefreshButton),
            matching: find.byIcon(Icons.refresh),
          ),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
      'BlocRefreshLoadingBuilder bridges bloc loading state and swaps blocs '
      'cleanly',
      (WidgetTester tester) async {
        final _TestLoadingCubit cubitA = _TestLoadingCubit(initialState: false);
        final _TestLoadingCubit cubitB = _TestLoadingCubit(initialState: true);
        addTearDown(() async {
          await cubitA.close();
          await cubitB.close();
        });

        Widget buildWith(_TestLoadingCubit cubit) {
          return MaterialApp(
            home: Scaffold(
              body: BlocProvider<_TestLoadingCubit>.value(
                value: cubit,
                child: BlocRefreshLoadingBuilder<_TestLoadingCubit, bool>(
                  isLoading: (bool loading) => loading,
                  builder:
                      (
                        BuildContext context,
                        ValueListenable<bool> isRefreshLoading,
                      ) {
                        return CardScaffoldHeader(
                          title: 'Dynamic Card',
                          onMoreIconPressed: () {},
                          onRefreshPressed: () {},
                          isRefreshLoading: isRefreshLoading,
                        );
                      },
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildWith(cubitA));
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        cubitA.setLoading(isLoading: true);
        await tester.pump();
        expect(find.byType(SyriusLoadingWidget), findsOneWidget);

        cubitA.setLoading(isLoading: false);
        await tester.pump();
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        await tester.pumpWidget(buildWith(cubitB));
        await tester.pump();
        expect(find.byType(SyriusLoadingWidget), findsOneWidget);

        cubitB.setLoading(isLoading: false);
        await tester.pump();
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets(
      'BlocRefreshLoadingBuilder resubscribes when BlocProvider.value swaps '
      'blocs while reusing the same child instance without rebuilding on '
      'state changes',
      (WidgetTester tester) async {
        final _TestLoadingCubit cubitA = _TestLoadingCubit(initialState: false);
        final _TestLoadingCubit cubitB = _TestLoadingCubit(initialState: true);
        addTearDown(() async {
          await cubitA.close();
          await cubitB.close();
        });

        int builderCallCount = 0;
        final Widget reusedChild =
            BlocRefreshLoadingBuilder<_TestLoadingCubit, bool>(
              isLoading: (bool loading) => loading,
              builder:
                  (
                    BuildContext context,
                    ValueListenable<bool> isRefreshLoading,
                  ) {
                    builderCallCount++;
                    return CardScaffoldHeader(
                      title: 'Reused Child Card',
                      onMoreIconPressed: () {},
                      onRefreshPressed: () {},
                      isRefreshLoading: isRefreshLoading,
                    );
                  },
            );

        Widget buildWith(_TestLoadingCubit cubit) {
          return MaterialApp(
            home: Scaffold(
              body: BlocProvider<_TestLoadingCubit>.value(
                value: cubit,
                child: reusedChild,
              ),
            ),
          );
        }

        await tester.pumpWidget(buildWith(cubitA));
        expect(builderCallCount, 1);
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        // State emissions update RefreshButton without rebuilding builder.
        cubitA.setLoading(isLoading: true);
        await tester.pump();
        expect(builderCallCount, 1);
        expect(find.byType(SyriusLoadingWidget), findsOneWidget);

        cubitA.setLoading(isLoading: false);
        await tester.pump();
        expect(builderCallCount, 1);
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        // Swapping provider value while reusing the exact same child instance
        // must resubscribe to cubitB and ignore subsequent cubitA emissions.
        await tester.pumpWidget(buildWith(cubitB));
        await tester.pump();
        expect(find.byType(SyriusLoadingWidget), findsOneWidget);

        cubitB.setLoading(isLoading: false);
        await tester.pump();
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        cubitA.setLoading(isLoading: true);
        await tester.pump();
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byType(SyriusLoadingWidget), findsNothing);
      },
    );

    test(
      'FetchBloc.isLoadingListenable tracks in-flight requests cleanly',
      () async {
      final Completer<String> completer = Completer<String>();
      final _TestFetchBloc bloc = _TestFetchBloc(
        zenon: _MockZenon(),
        fetchHandler: (_) => completer.future,
      );
      addTearDown(bloc.close);

      final List<bool> loadingValues = <bool>[];
      bloc.isLoadingListenable.addListener(() {
        loadingValues.add(bloc.isLoadingListenable.value);
      });

      expect(bloc.isLoadingListenable.value, isFalse);

      bloc.add(FetchRequestData(address: emptyAddress));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.isLoadingListenable.value, isTrue);

      completer.complete('ok');
      await Future<void>.delayed(Duration.zero);

      expect(bloc.isLoadingListenable.value, isFalse);
      expect(loadingValues, equals(<bool>[true, false]));
    });
  });
}
