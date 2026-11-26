import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app_main;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/refresh_button/refresh_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

import '../../helpers/hydrated_bloc.dart';

class _MockNotificationsListBloc
    extends MockBloc<NotificationsListEvent, NotificationsListState>
    implements NotificationsListBloc {}

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

void main() {
  late _MockNotificationsListBloc mockBloc;
  late _MockSharedPrefsService mockSharedPrefsService;
  late _MockNotificationsBloc mockNotificationsBloc;
  SharedPrefsService? previousSharedPrefsService;
  bool registeredNotificationsBloc = false;

  setUpAll(() {
    initHydratedStorage();
    registerFallbackValue(const NotificationsListStarted());
    registerFallbackValue(FailureException());
  });

  setUp(() {
    mockBloc = _MockNotificationsListBloc();
    mockSharedPrefsService = _MockSharedPrefsService();
    mockNotificationsBloc = _MockNotificationsBloc();
    when(
      () => mockSharedPrefsService.get(
        any(),
        defaultValue: any<dynamic>(named: 'defaultValue'),
      ),
    ).thenReturn(false);
    when(
      () => mockNotificationsBloc.recordErrorNotification(any<Object>(), any()),
    ).thenAnswer((_) async {});

    previousSharedPrefsService = app_main.sharedPrefsService;
    app_main.sharedPrefsService = mockSharedPrefsService;

    if (!app_main.sl.isRegistered<NotificationsBloc>()) {
      app_main.sl.registerSingleton<NotificationsBloc>(mockNotificationsBloc);
      registeredNotificationsBloc = true;
    } else {
      registeredNotificationsBloc = false;
    }
  });

  tearDown(() async {
    app_main.sharedPrefsService = previousSharedPrefsService;
    if (registeredNotificationsBloc &&
        app_main.sl.isRegistered<NotificationsBloc>()) {
      await app_main.sl.unregister<NotificationsBloc>();
    }
  });

  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 700,
          child: NotificationsCard(bloc: mockBloc),
        ),
      ),
    );
  }

  final StoredWalletNotification sampleEntry = StoredWalletNotification(
    key: 42,
    notification: WalletNotification(
      title: 'Payment received',
      timestamp: DateTime(2026, 3, 15, 14, 30).millisecondsSinceEpoch,
      details: 'Received 10 ZNN from z1q...',
      type: NotificationType.paymentReceived,
    ),
  );

  final StoredWalletNotification nullTimestampEntry = StoredWalletNotification(
    key: 43,
    notification: WalletNotification(
      title: 'Legacy entry',
      timestamp: null,
      details: '',
      type: NotificationType.error,
    ),
  );

  group('NotificationsCard', () {
    testWidgets('shows loading widget when NotificationsListLoading', (
      WidgetTester tester,
    ) async {
      whenListen<NotificationsListState>(
        mockBloc,
        const Stream<NotificationsListState>.empty(),
        initialState: const NotificationsListLoading(),
      );

      await tester.pumpWidget(buildSubject());

      expect(find.text('Notifications'), findsAtLeastNWidgets(1));
      expect(
        find.descendant(
          of: find.byType(RefreshButton),
          matching: find.byType(SyriusLoadingWidget),
        ),
        findsNWidgets(2),
      );
      expect(find.byType(SyriusLoadingWidget), findsNWidgets(3));
      final IconButton clearAllButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
      );
      expect(clearAllButton.onPressed, isNull);
    });

    testWidgets(
      'shows empty state and disables Clear All when no notifications exist',
      (WidgetTester tester) async {
        whenListen<NotificationsListState>(
          mockBloc,
          const Stream<NotificationsListState>.empty(),
          initialState: const NotificationsListPopulated(
            notifications: <StoredWalletNotification>[],
          ),
        );

        await tester.pumpWidget(buildSubject());

        expect(find.text('No notifications'), findsOneWidget);
        final IconButton clearAllButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
        );
        expect(clearAllButton.onPressed, isNull);
      },
    );

    testWidgets(
      'renders populated rows including null timestamp fallback and supports '
      'single-item delete and refresh',
      (WidgetTester tester) async {
        whenListen<NotificationsListState>(
          mockBloc,
          const Stream<NotificationsListState>.empty(),
          initialState: NotificationsListPopulated(
            notifications: <StoredWalletNotification>[
              sampleEntry,
              nullTimestampEntry,
            ],
          ),
        );

        await tester.pumpWidget(buildSubject());

        expect(find.text('Description'), findsAtLeastNWidgets(1));
        expect(find.text('Date'), findsOneWidget);
        expect(find.text('Time'), findsOneWidget);
        expect(find.text('Payment received'), findsOneWidget);
        expect(find.text('Legacy entry'), findsOneWidget);
        expect(find.text('-'), findsNWidgets(2));

        // Expand details and verify copy button appears for non-empty details.
        await tester.tap(find.text('Payment received'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Received 10 ZNN from z1q...'), findsOneWidget);
        expect(find.byType(CopyToClipboardButton), findsOneWidget);

        // Delete first row by key.
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pump();
        verify(
          () => mockBloc.add(NotificationDeleteRequested(key: sampleEntry.key)),
        ).called(1);

        // Refresh button dispatches refresh event.
        await tester.tap(find.byIcon(Icons.refresh).first);
        await tester.pump();
        verify(
          () => mockBloc.add(const NotificationsListRefreshRequested()),
        ).called(1);
      },
    );

    testWidgets(
      'confirms before clearing all notifications and respects No vs Yes',
      (WidgetTester tester) async {
        when(() => mockBloc.isClosed).thenReturn(false);
        whenListen<NotificationsListState>(
          mockBloc,
          const Stream<NotificationsListState>.empty(),
          initialState: NotificationsListPopulated(
            notifications: <StoredWalletNotification>[sampleEntry],
          ),
        );

        await tester.pumpWidget(buildSubject());

        // Tap Clear All and cancel with No.
        await tester.tap(
          find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text(
            'Are you sure you want to delete all notifications? '
            'This action cannot be undone.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('dialog_no_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        verifyNever(() => mockBloc.add(const NotificationsClearAllRequested()));

        // Tap Clear All and confirm with Yes.
        await tester.tap(
          find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const Key('dialog_yes_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        verify(
          () => mockBloc.add(const NotificationsClearAllRequested()),
        ).called(1);
      },
    );

    testWidgets(
      'hides Clear All header action when card is hidden in discreet mode',
      (WidgetTester tester) async {
        when(
          () => mockSharedPrefsService.get(
            any(),
            defaultValue: any<dynamic>(named: 'defaultValue'),
          ),
        ).thenReturn(true);

        whenListen<NotificationsListState>(
          mockBloc,
          const Stream<NotificationsListState>.empty(),
          initialState: NotificationsListPopulated(
            notifications: <StoredWalletNotification>[sampleEntry],
          ),
        );

        await tester.pumpWidget(buildSubject());

        expect(
          find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
          findsNothing,
        );
      },
    );

    testWidgets('shows foreground error when actionError is emitted', (
      WidgetTester tester,
    ) async {
      final StreamController<NotificationsListState> controller =
          StreamController<NotificationsListState>.broadcast();
      addTearDown(controller.close);

      whenListen<NotificationsListState>(
        mockBloc,
        controller.stream,
        initialState: NotificationsListPopulated(
          notifications: <StoredWalletNotification>[sampleEntry],
        ),
      );

      await tester.pumpWidget(buildSubject());

      controller.add(
        NotificationsListPopulated(
          notifications: <StoredWalletNotification>[sampleEntry],
          actionError: NotificationsListActionError.clearAll,
          errorNonce: 1,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Error while clearing notifications'), findsOneWidget);
      verify(
        () => mockNotificationsBloc.recordErrorNotification(
          any<Object>(),
          'Error while clearing notifications',
        ),
      ).called(1);

      // Drain ToastUtils 3-second dismissal timer cleanly.
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
