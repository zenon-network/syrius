import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockWsClient extends Mock implements WsClient {}

class _MockLedger extends Mock implements LedgerApi {}

class _FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(_FakeAddress());
  });

  group('MultipleBalanceBloc singleton provider lifecycle', () {
    late _MockZenon mockZenon;
    late _MockWsClient mockWsClient;
    late _MockLedger mockLedger;
    late MultipleBalanceBloc singletonBloc;
    late NotificationsBloc notificationsBloc;
    late bool hadMultipleBalanceBloc;
    late MultipleBalanceBloc? previousMultipleBalanceBloc;
    late bool hadNotificationsBloc;
    late NotificationsBloc? previousNotificationsBloc;
    late Zenon? previousZenon;

    final String testAddress = emptyAddress.toString();
    final AccountInfo testAccountInfo = AccountInfo(
      address: emptyAddress.toString(),
      blockCount: 1,
      balanceInfoList: <BalanceInfoListItem>[
        BalanceInfoListItem(token: kZnnCoin, balance: BigInt.from(10)),
      ],
    );

    setUp(() async {
      mockZenon = _MockZenon();
      mockWsClient = _MockWsClient();
      mockLedger = _MockLedger();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockZenon.ledger).thenReturn(mockLedger);
      when(
        () => mockWsClient.restartedStream,
      ).thenAnswer((_) => const Stream<bool>.empty());
      when(
        () => mockLedger.getAccountInfoByAddress(any()),
      ).thenAnswer((_) async => testAccountInfo);

      previousZenon = zenon;
      zenon = mockZenon;

      hadMultipleBalanceBloc = sl.isRegistered<MultipleBalanceBloc>();
      previousMultipleBalanceBloc = hadMultipleBalanceBloc
          ? sl<MultipleBalanceBloc>()
          : null;
      if (hadMultipleBalanceBloc) {
        await sl.unregister<MultipleBalanceBloc>();
      }
      singletonBloc = MultipleBalanceBloc(zenon: mockZenon);
      sl.registerSingleton<MultipleBalanceBloc>(singletonBloc);

      hadNotificationsBloc = sl.isRegistered<NotificationsBloc>();
      previousNotificationsBloc = hadNotificationsBloc
          ? sl<NotificationsBloc>()
          : null;
      if (hadNotificationsBloc) {
        await sl.unregister<NotificationsBloc>();
      }
      notificationsBloc = NotificationsBloc();
      sl.registerSingleton<NotificationsBloc>(notificationsBloc);
    });

    tearDown(() async {
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
      await singletonBloc.close();
      await notificationsBloc.close();
    });

    testWidgets(
      'disposing MyApp provider subtree does not close singleton '
      'MultipleBalanceBloc',
      (WidgetTester tester) async {
        MultipleBalanceBloc? resolvedBloc;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: buildMyAppBlocProviders(),
            child: Builder(
              builder: (BuildContext context) {
                resolvedBloc = context.read<MultipleBalanceBloc>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolvedBloc, same(singletonBloc));
        expect(singletonBloc.isClosed, isFalse);

        // Dispose the provider subtree.
        await tester.pumpWidget(const SizedBox.shrink());

        expect(singletonBloc.isClosed, isFalse);

        // Verify the singleton still accepts events and emits new states.
        final MultipleBalanceState result =
            (await tester.runAsync<MultipleBalanceState>(() async {
              final Future<MultipleBalanceState> fetched = singletonBloc.stream
                  .firstWhere(
                    (MultipleBalanceState state) =>
                        state.status == MultipleBalanceStatus.success,
                  )
                  .timeout(const Duration(seconds: 5));
              singletonBloc.add(
                MultipleBalanceFetch(addresses: <String>[testAddress]),
              );
              return await fetched;
            }))!;
        expect(result.data?[testAddress]?.blockCount, 1);
      },
    );

    testWidgets(
      'disposing and rebuilding MainAppContainer provider subtree does not '
      'close singleton MultipleBalanceBloc',
      (WidgetTester tester) async {
        MultipleBalanceBloc? firstResolved;
        MultipleBalanceBloc? secondResolved;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: buildMainAppContainerBlocProviders(),
            child: Builder(
              builder: (BuildContext context) {
                firstResolved = context.read<MultipleBalanceBloc>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(firstResolved, same(singletonBloc));
        expect(singletonBloc.isClosed, isFalse);

        // Simulate container disposal (e.g., lock/reset/route replacement).
        await tester.pumpWidget(const SizedBox.shrink());
        expect(singletonBloc.isClosed, isFalse);

        // Remount container providers and verify the same open singleton works.
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: buildMainAppContainerBlocProviders(),
            child: Builder(
              builder: (BuildContext context) {
                secondResolved = context.read<MultipleBalanceBloc>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(secondResolved, same(singletonBloc));
        expect(singletonBloc.isClosed, isFalse);

        final MultipleBalanceState result =
            (await tester.runAsync<MultipleBalanceState>(() async {
              final Future<MultipleBalanceState> fetched = singletonBloc.stream
                  .firstWhere(
                    (MultipleBalanceState state) =>
                        state.status == MultipleBalanceStatus.success,
                  )
                  .timeout(const Duration(seconds: 5));
              singletonBloc.add(
                MultipleBalanceFetch(addresses: <String>[testAddress]),
              );
              return await fetched;
            }))!;
        expect(result.data?[testAddress]?.blockCount, 1);
      },
    );
  });
}
