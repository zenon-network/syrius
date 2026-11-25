import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/refresh_button/refresh_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

class _TrackingValueNotifier<T> extends ValueNotifier<T> {
  _TrackingValueNotifier(super._value);

  bool get hasAnyListeners => hasListeners;
}

void main() {
  group('RefreshButton', () {
    testWidgets(
      'renders refresh icon and invokes onPressed without a listenable',
      (WidgetTester tester) async {
        int pressCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RefreshButton(onPressed: () => pressCount++)),
          ),
        );

        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byType(SyriusLoadingWidget), findsNothing);

        await tester.tap(find.byType(IconButton));
        expect(pressCount, 1);
      },
    );

    testWidgets(
      'rebuilds between refresh icon and loading indicator via listenable',
      (WidgetTester tester) async {
        int pressCount = 0;
        final _TrackingValueNotifier<bool> isLoading =
            _TrackingValueNotifier<bool>(false);
        addTearDown(isLoading.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RefreshButton(
                onPressed: () => pressCount++,
                isLoadingListenable: isLoading,
              ),
            ),
          ),
        );

        expect(isLoading.hasAnyListeners, isTrue);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byType(SyriusLoadingWidget), findsNothing);

        await tester.tap(find.byType(IconButton));
        expect(pressCount, 1);

        isLoading.value = true;
        await tester.pump();

        expect(find.byIcon(Icons.refresh), findsNothing);
        expect(find.byType(SyriusLoadingWidget), findsOneWidget);
        expect(
          tester.widget<IconButton>(find.byType(IconButton)).onPressed,
          isNull,
        );

        await tester.tap(find.byType(IconButton));
        expect(pressCount, 1);

        isLoading.value = false;
        await tester.pump();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byType(SyriusLoadingWidget), findsNothing);

        await tester.tap(find.byType(IconButton));
        expect(pressCount, 2);
      },
    );

    testWidgets('swaps listeners cleanly when isLoadingListenable changes', (
      WidgetTester tester,
    ) async {
      final _TrackingValueNotifier<bool> firstNotifier =
          _TrackingValueNotifier<bool>(false);
      final _TrackingValueNotifier<bool> secondNotifier =
          _TrackingValueNotifier<bool>(true);
      addTearDown(() {
        firstNotifier.dispose();
        secondNotifier.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshButton(
              onPressed: () {},
              isLoadingListenable: firstNotifier,
            ),
          ),
        ),
      );

      expect(firstNotifier.hasAnyListeners, isTrue);
      expect(secondNotifier.hasAnyListeners, isFalse);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshButton(
              onPressed: () {},
              isLoadingListenable: secondNotifier,
            ),
          ),
        ),
      );

      expect(firstNotifier.hasAnyListeners, isFalse);
      expect(secondNotifier.hasAnyListeners, isTrue);
      expect(find.byType(SyriusLoadingWidget), findsOneWidget);

      firstNotifier.value = true;
      await tester.pump();
      expect(find.byType(SyriusLoadingWidget), findsOneWidget);

      secondNotifier.value = false;
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets(
      'detaches and reattaches listener when toggling between null and '
      'non-null listenable',
      (WidgetTester tester) async {
        final _TrackingValueNotifier<bool> isLoading =
            _TrackingValueNotifier<bool>(true);
        addTearDown(isLoading.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RefreshButton(
                onPressed: () {},
                isLoadingListenable: isLoading,
              ),
            ),
          ),
        );

        expect(isLoading.hasAnyListeners, isTrue);
        expect(find.byType(SyriusLoadingWidget), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RefreshButton(onPressed: () {})),
          ),
        );

        expect(isLoading.hasAnyListeners, isFalse);
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RefreshButton(
                onPressed: () {},
                isLoadingListenable: isLoading,
              ),
            ),
          ),
        );

        expect(isLoading.hasAnyListeners, isTrue);
        expect(find.byType(SyriusLoadingWidget), findsOneWidget);
      },
    );

    testWidgets('removes listener on disposal without leaking', (
      WidgetTester tester,
    ) async {
      final _TrackingValueNotifier<bool> isLoading =
          _TrackingValueNotifier<bool>(false);
      addTearDown(isLoading.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshButton(
              onPressed: () {},
              isLoadingListenable: isLoading,
            ),
          ),
        ),
      );

      expect(isLoading.hasAnyListeners, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(isLoading.hasAnyListeners, isFalse);
    });
  });
}
