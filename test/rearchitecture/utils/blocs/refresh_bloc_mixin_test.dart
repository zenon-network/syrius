import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/refresh_bloc_mixin.dart';

class _TestRefreshConsumer with RefreshBlocMixin {}

void main() {
  group('RefreshBlocMixin', () {
    test(
      'invokes callback exactly once per true reconnect event without '
      'multiplying listeners',
      () async {
        final StreamController<bool> controller =
            StreamController<bool>.broadcast();
        addTearDown(controller.close);

        final _TestRefreshConsumer consumer = _TestRefreshConsumer();
        addTearDown(consumer.cancelStreamSubscription);

        int callbackCount = 0;
        consumer.listenToWsRestart(
          () => callbackCount++,
          restartedStream: controller.stream,
        );

        controller.add(false);
        await Future<void>.delayed(Duration.zero);
        expect(callbackCount, 0);

        controller.add(true);
        await Future<void>.delayed(Duration.zero);
        expect(callbackCount, 1);

        controller.add(true);
        await Future<void>.delayed(Duration.zero);
        expect(callbackCount, 2);

        controller.add(true);
        await Future<void>.delayed(Duration.zero);
        expect(callbackCount, 3);
      },
    );

    test(
      'cancels previous subscription when listenToWsRestart is called again',
      () async {
        final StreamController<bool> firstController =
            StreamController<bool>.broadcast();
        final StreamController<bool> secondController =
            StreamController<bool>.broadcast();
        addTearDown(firstController.close);
        addTearDown(secondController.close);

        final _TestRefreshConsumer consumer = _TestRefreshConsumer();
        addTearDown(consumer.cancelStreamSubscription);

        int firstCount = 0;
        int secondCount = 0;
        consumer
          ..listenToWsRestart(
            () => firstCount++,
            restartedStream: firstController.stream,
          )
          ..listenToWsRestart(
            () => secondCount++,
            restartedStream: secondController.stream,
          );

        firstController.add(true);
        secondController.add(true);
        await Future<void>.delayed(Duration.zero);

        expect(firstCount, 0);
        expect(secondCount, 1);
      },
    );

    test(
      'stops invoking callback after cancelStreamSubscription',
      () async {
        final StreamController<bool> controller =
            StreamController<bool>.broadcast();
        addTearDown(controller.close);

        final _TestRefreshConsumer consumer = _TestRefreshConsumer();

        int callbackCount = 0;
        consumer.listenToWsRestart(
          () => callbackCount++,
          restartedStream: controller.stream,
        );

        controller.add(true);
        await Future<void>.delayed(Duration.zero);
        expect(callbackCount, 1);

        await consumer.cancelStreamSubscription();

        controller.add(true);
        await Future<void>.delayed(Duration.zero);
        expect(callbackCount, 1);
      },
    );
  });
}
