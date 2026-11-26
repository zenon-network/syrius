import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class _MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NotificationDismissed());
  });

  group('NotificationWidget', () {
    late _MockNotificationsBloc mockBloc;
    late Tabs? previousPage;

    setUp(() {
      mockBloc = _MockNotificationsBloc();
      previousPage = kCurrentPage;
      kCurrentPage = Tabs.dashboard;
    });

    tearDown(() async {
      kCurrentPage = previousPage;
      await mockBloc.close();
    });

    Widget buildSubject({
      VoidCallback? onSeeMorePressed,
      VoidCallback? onDismissPressed,
      VoidCallback? onNewNotificationCallback,
      bool popBeforeSeeMoreIsPressed = false,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotificationWidget(
            bloc: mockBloc,
            onSeeMorePressed: onSeeMorePressed,
            onDismissPressed: onDismissPressed,
            onNewNotificationCallback: onNewNotificationCallback,
            popBeforeSeeMoreIsPressed: popBeforeSeeMoreIsPressed,
          ),
        ),
      );
    }

    final WalletNotification sampleNotification = WalletNotification(
      title: 'Transaction sent',
      timestamp: 1000,
      details: 'Hash: abc',
      type: NotificationType.paymentSent,
    );

    testWidgets('renders empty when no notification is active', (
      WidgetTester tester,
    ) async {
      whenListen<NotificationsState>(
        mockBloc,
        const Stream<NotificationsState>.empty(),
        initialState: const NotificationsState(),
      );

      await tester.pumpWidget(buildSubject(onSeeMorePressed: () {}));

      expect(find.text('Dismiss'), findsNothing);
      expect(find.text('See more'), findsNothing);
    });

    testWidgets(
      'displays active notification with localized actions and dispatches '
      'dismiss on tap',
      (WidgetTester tester) async {
        whenListen<NotificationsState>(
          mockBloc,
          const Stream<NotificationsState>.empty(),
          initialState: NotificationsState(
            activeNotification: sampleNotification,
            revision: 7,
          ),
        );

        bool seeMoreCalled = false;
        await tester.pumpWidget(
          buildSubject(onSeeMorePressed: () => seeMoreCalled = true),
        );

        expect(find.text('Transaction sent'), findsOneWidget);
        expect(find.text('See more'), findsOneWidget);
        expect(find.text('Dismiss'), findsOneWidget);

        await tester.tap(find.text('Dismiss'));
        await tester.pump();

        verify(
          () => mockBloc.add(const NotificationDismissed(revision: 7)),
        ).called(1);
        expect(seeMoreCalled, isFalse);
      },
    );

    testWidgets(
      'invokes onSeeMorePressed and dispatches dismiss when See more tapped',
      (WidgetTester tester) async {
        whenListen<NotificationsState>(
          mockBloc,
          const Stream<NotificationsState>.empty(),
          initialState: NotificationsState(
            activeNotification: sampleNotification,
            revision: 7,
          ),
        );

        bool seeMoreCalled = false;
        await tester.pumpWidget(
          buildSubject(onSeeMorePressed: () => seeMoreCalled = true),
        );

        await tester.tap(find.text('See more'));
        await tester.pump();

        expect(seeMoreCalled, isTrue);
        verify(
          () => mockBloc.add(const NotificationDismissed(revision: 7)),
        ).called(1);
      },
    );

    testWidgets('hides See more button when on lock tab', (
      WidgetTester tester,
    ) async {
      kCurrentPage = Tabs.lock;
      whenListen<NotificationsState>(
        mockBloc,
        const Stream<NotificationsState>.empty(),
        initialState: NotificationsState(
          activeNotification: sampleNotification,
          revision: 1,
        ),
      );

      await tester.pumpWidget(buildSubject(onSeeMorePressed: () {}));

      expect(find.text('Transaction sent'), findsOneWidget);
      expect(find.text('See more'), findsNothing);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets(
      'fires onNewNotificationCallback and onDismissPressed on state changes',
      (WidgetTester tester) async {
        final StreamController<NotificationsState> controller =
            StreamController<NotificationsState>.broadcast();
        addTearDown(controller.close);

        whenListen<NotificationsState>(
          mockBloc,
          controller.stream,
          initialState: const NotificationsState(),
        );

        int newCount = 0;
        int dismissCount = 0;
        await tester.pumpWidget(
          buildSubject(
            onNewNotificationCallback: () => newCount++,
            onDismissPressed: () => dismissCount++,
          ),
        );

        controller.add(
          NotificationsState(
            activeNotification: sampleNotification,
            revision: 1,
          ),
        );
        await tester.pump();
        expect(newCount, 1);
        expect(dismissCount, 0);

        // Consecutive identical notification still notifies via revision bump.
        controller.add(
          NotificationsState(
            activeNotification: sampleNotification,
            revision: 2,
          ),
        );
        await tester.pump();
        expect(newCount, 2);
        expect(dismissCount, 0);

        controller.add(const NotificationsState(revision: 2));
        await tester.pump();
        expect(newCount, 2);
        expect(dismissCount, 1);
      },
    );
  });
}
