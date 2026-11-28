import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_theme_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_beneficiary_address_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_generated_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'helpers/hydrated_bloc.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockWsClient extends Mock implements WsClient {}

void main() {
  initHydratedStorage();

  group('MyApp root widget tree', () {
    late _MockZenon mockZenon;
    late _MockWsClient mockWsClient;
    late LatestTransactionsBloc latestTransactionsBloc;
    late PendingTransactionsBloc pendingTransactionsBloc;
    late MultipleBalanceBloc multipleBalanceBloc;
    late NotificationsBloc notificationsBloc;

    late LatestTransactionsBloc? previousLatestTransactionsBloc;
    late PendingTransactionsBloc? previousPendingTransactionsBloc;
    late MultipleBalanceBloc? previousMultipleBalanceBloc;
    late NotificationsBloc? previousNotificationsBloc;
    late Zenon? previousZenon;
    late Tabs? previousCurrentPage;
    late String? previousLocalIpAddress;

    setUp(() async {
      mockZenon = _MockZenon();
      mockWsClient = _MockWsClient();
      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(
        () => mockWsClient.restartedStream,
      ).thenAnswer((_) => const Stream<bool>.empty());

      previousZenon = zenon;
      previousCurrentPage = kCurrentPage;
      previousLocalIpAddress = kLocalIpAddress;
      zenon = mockZenon;
      kCurrentPage = Tabs.dashboard;

      previousLatestTransactionsBloc = sl.isRegistered<LatestTransactionsBloc>()
          ? sl<LatestTransactionsBloc>()
          : null;
      if (previousLatestTransactionsBloc != null) {
        await sl.unregister<LatestTransactionsBloc>();
      }
      latestTransactionsBloc = LatestTransactionsBloc(zenon: mockZenon);
      sl.registerSingleton<LatestTransactionsBloc>(latestTransactionsBloc);

      previousPendingTransactionsBloc =
          sl.isRegistered<PendingTransactionsBloc>()
          ? sl<PendingTransactionsBloc>()
          : null;
      if (previousPendingTransactionsBloc != null) {
        await sl.unregister<PendingTransactionsBloc>();
      }
      pendingTransactionsBloc = PendingTransactionsBloc(zenon: mockZenon);
      sl.registerSingleton<PendingTransactionsBloc>(pendingTransactionsBloc);

      previousMultipleBalanceBloc = sl.isRegistered<MultipleBalanceBloc>()
          ? sl<MultipleBalanceBloc>()
          : null;
      if (previousMultipleBalanceBloc != null) {
        await sl.unregister<MultipleBalanceBloc>();
      }
      multipleBalanceBloc = MultipleBalanceBloc(zenon: mockZenon);
      sl.registerSingleton<MultipleBalanceBloc>(multipleBalanceBloc);

      previousNotificationsBloc = sl.isRegistered<NotificationsBloc>()
          ? sl<NotificationsBloc>()
          : null;
      if (previousNotificationsBloc != null) {
        await sl.unregister<NotificationsBloc>();
      }
      notificationsBloc = NotificationsBloc();
      sl.registerSingleton<NotificationsBloc>(notificationsBloc);
    });

    tearDown(() async {
      if (sl.isRegistered<LatestTransactionsBloc>()) {
        await sl.unregister<LatestTransactionsBloc>();
      }
      if (previousLatestTransactionsBloc != null) {
        sl.registerSingleton<LatestTransactionsBloc>(
          previousLatestTransactionsBloc!,
        );
      }
      if (sl.isRegistered<PendingTransactionsBloc>()) {
        await sl.unregister<PendingTransactionsBloc>();
      }
      if (previousPendingTransactionsBloc != null) {
        sl.registerSingleton<PendingTransactionsBloc>(
          previousPendingTransactionsBloc!,
        );
      }
      if (sl.isRegistered<MultipleBalanceBloc>()) {
        await sl.unregister<MultipleBalanceBloc>();
      }
      if (previousMultipleBalanceBloc != null) {
        sl.registerSingleton<MultipleBalanceBloc>(previousMultipleBalanceBloc!);
      }
      if (sl.isRegistered<NotificationsBloc>()) {
        await sl.unregister<NotificationsBloc>();
      }
      if (previousNotificationsBloc != null) {
        sl.registerSingleton<NotificationsBloc>(previousNotificationsBloc!);
      }
      zenon = previousZenon;
      kCurrentPage = previousCurrentPage;
      kLocalIpAddress = previousLocalIpAddress;
      await latestTransactionsBloc.close();
      await pendingTransactionsBloc.close();
      await multipleBalanceBloc.close();
      await notificationsBloc.close();
    });

    testWidgets(
      'mounts MaterialApp and SplashScreen with root providers and responds '
      'to theme changes and pointer activity',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());

        expect(tester.takeException(), isNull);
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(SplashScreen), findsOneWidget);

        final BuildContext splashContext = tester.element(
          find.byType(SplashScreen),
        );

        // Verify root BLoCs and ChangeNotifier providers are mounted above
        // MaterialApp and reachable from the initial route.
        expect(
          splashContext.read<NotificationsBloc>(),
          same(notificationsBloc),
        );
        expect(
          splashContext.read<LatestTransactionsBloc>(),
          same(latestTransactionsBloc),
        );
        expect(
          splashContext.read<PendingTransactionsBloc>(),
          same(pendingTransactionsBloc),
        );
        expect(
          splashContext.read<MultipleBalanceBloc>(),
          same(multipleBalanceBloc),
        );
        expect(
          splashContext.read<SelectedAddressNotifier>(),
          isA<SelectedAddressNotifier>(),
        );
        expect(
          splashContext.read<PlasmaBeneficiaryAddressCubit>(),
          isA<PlasmaBeneficiaryAddressCubit>(),
        );
        expect(
          splashContext.read<PlasmaGeneratedNotifier>(),
          isA<PlasmaGeneratedNotifier>(),
        );
        expect(
          splashContext.read<TextScalingNotifier>(),
          isA<TextScalingNotifier>(),
        );
        expect(
          splashContext.read<ValueNotifier<List<String>>>(),
          isA<ValueNotifier<List<String>>>(),
        );

        final AppThemeNotifier themeNotifier = splashContext
            .read<AppThemeNotifier>();
        final LockBloc lockBloc = splashContext.read<LockBloc>();

        final FocusNode initialKeyboardFocusNode = tester
            .widget<KeyboardListener>(find.byType(KeyboardListener))
            .focusNode;

        // Verify AppThemeNotifier drives MaterialApp.themeMode cleanly and
        // preserves the KeyboardListener FocusNode across rebuilds.
        themeNotifier.changeThemeMode(ThemeMode.light);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.light,
        );
        expect(
          tester
              .widget<KeyboardListener>(find.byType(KeyboardListener))
              .focusNode,
          same(initialKeyboardFocusNode),
        );

        // Verify root Listener resets the LockBloc timer on user interaction.
        final Future<WalletLockState> nextPointerLockState = lockBloc.stream
            .firstWhere(
              (WalletLockState state) => state.action == LockAction.resetTimer,
            );
        await tester.tap(find.byType(SplashScreen));
        await tester.pump();
        final WalletLockState emittedFromPointer = await nextPointerLockState
            .timeout(const Duration(seconds: 2));
        expect(emittedFromPointer.action, LockAction.resetTimer);

        // Verify root KeyboardListener resets the LockBloc timer on key input.
        initialKeyboardFocusNode.requestFocus();
        await tester.pump();
        final Future<WalletLockState> nextKeyLockState = lockBloc.stream
            .firstWhere(
              (WalletLockState state) =>
                  state.action == LockAction.resetTimer &&
                  state.sequence > emittedFromPointer.sequence,
            );
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        final WalletLockState emittedFromKey = await nextKeyLockState.timeout(
          const Duration(seconds: 2),
        );
        expect(emittedFromKey.action, LockAction.resetTimer);

        // Verify navigating to the onboarding route renders inside MyApp's
        // Layout + MaterialApp + AppLocalizations tree with zero exceptions.
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        globalNavigatorKey.currentState!.pushReplacementNamed(
          AccessWalletScreen.route,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AccessWalletScreen), findsOneWidget);

        // Unmount cleanly and verify singleton BLoCs remain open.
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
        expect(notificationsBloc.isClosed, isFalse);
        expect(latestTransactionsBloc.isClosed, isFalse);
        expect(pendingTransactionsBloc.isClosed, isFalse);
        expect(multipleBalanceBloc.isClosed, isFalse);
      },
    );
  });
}
