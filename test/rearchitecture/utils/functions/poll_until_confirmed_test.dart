import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

void main() {
  group('pollUntilConfirmed', () {
    test(
      'returns true immediately on first confirmed read without sleeping',
      () async {
        int fetchCount = 0;
        final List<Duration> sleeps = <Duration>[];

        final bool confirmed = await pollUntilConfirmed<int>(
          fetch: () async {
            fetchCount += 1;
            return 42;
          },
          isConfirmed: (int value) => value == 42,
          delay: (Duration duration) async => sleeps.add(duration),
        );

        expect(confirmed, isTrue);
        expect(fetchCount, 1);
        expect(sleeps, isEmpty);
      },
    );

    test(
      'retries across unconfirmed reads, transient errors, and fetch '
      'TimeoutExceptions while budget remains',
      () async {
        DateTime currentTime = DateTime(2026);
        final List<Duration> sleeps = <Duration>[];
        int attempts = 0;

        final bool confirmed = await pollUntilConfirmed<BigInt>(
          fetch: () async {
            attempts += 1;
            if (attempts == 1) {
              return BigInt.zero;
            }
            if (attempts == 2) {
              throw Exception('transient rpc error');
            }
            if (attempts == 3) {
              throw TimeoutException('single rpc call timed out');
            }
            return BigInt.from(5000);
          },
          isConfirmed: (BigInt value) => value >= BigInt.from(5000),
          timeout: const Duration(seconds: 30),
          now: () => currentTime,
          delay: (Duration duration) async {
            sleeps.add(duration);
            currentTime = currentTime.add(duration);
          },
        );

        expect(confirmed, isTrue);
        expect(attempts, 4);
        expect(
          sleeps,
          <Duration>[
            kDefaultConfirmationPollInterval,
            kDefaultConfirmationPollInterval,
            kDefaultConfirmationPollInterval,
          ],
        );
      },
    );

    test(
      'stops without sleeping past the deadline when remaining budget cannot '
      'fit another poll interval',
      () async {
        DateTime currentTime = DateTime(2026);
        final List<Duration> sleeps = <Duration>[];
        int attempts = 0;

        final bool confirmed = await pollUntilConfirmed<int>(
          fetch: () async {
            attempts += 1;
            return 0;
          },
          isConfirmed: (int value) => value > 0,
          pollInterval: const Duration(seconds: 3),
          timeout: const Duration(seconds: 7),
          now: () => currentTime,
          delay: (Duration duration) async {
            sleeps.add(duration);
            currentTime = currentTime.add(duration);
          },
        );

        expect(confirmed, isFalse);
        expect(attempts, 3);
        expect(
          sleeps,
          <Duration>[
            const Duration(seconds: 3),
            const Duration(seconds: 3),
          ],
        );
      },
    );

    test('returns false without fetching when timeout is zero', () async {
      int attempts = 0;
      final List<Duration> sleeps = <Duration>[];

      final bool confirmed = await pollUntilConfirmed<int>(
        fetch: () async {
          attempts += 1;
          return 1;
        },
        isConfirmed: (int value) => value > 0,
        timeout: Duration.zero,
        delay: (Duration duration) async => sleeps.add(duration),
      );

      expect(confirmed, isFalse);
      expect(attempts, 0);
      expect(sleeps, isEmpty);
    });

    test(
      'bounds a stalled fetch by the remaining timeout budget and returns '
      'false',
      () async {
        final Completer<int> stalledFetch = Completer<int>();
        int attempts = 0;

        final bool confirmed = await pollUntilConfirmed<int>(
          fetch: () {
            attempts += 1;
            return stalledFetch.future;
          },
          isConfirmed: (int value) => value > 0,
          pollInterval: const Duration(milliseconds: 5),
          timeout: const Duration(milliseconds: 25),
        );

        expect(confirmed, isFalse);
        expect(attempts, 1);
      },
    );

    test('returns false without fetching when already cancelled', () async {
      int attempts = 0;
      final List<Duration> sleeps = <Duration>[];

      final bool confirmed = await pollUntilConfirmed<int>(
        fetch: () async {
          attempts += 1;
          return 1;
        },
        isConfirmed: (int value) => value > 0,
        isCancelled: () => true,
        delay: (Duration duration) async => sleeps.add(duration),
      );

      expect(confirmed, isFalse);
      expect(attempts, 0);
      expect(sleeps, isEmpty);
    });

    test('stops immediately when cancelled during polling', () async {
      bool cancelled = false;
      int attempts = 0;
      final List<Duration> sleeps = <Duration>[];

      final bool confirmed = await pollUntilConfirmed<int>(
        fetch: () async {
          attempts += 1;
          if (attempts == 2) {
            cancelled = true;
          }
          return 0;
        },
        isConfirmed: (int value) => value > 0,
        timeout: const Duration(seconds: 30),
        isCancelled: () => cancelled,
        delay: (Duration duration) async => sleeps.add(duration),
      );

      expect(confirmed, isFalse);
      expect(attempts, 2);
      expect(sleeps, <Duration>[kDefaultConfirmationPollInterval]);
    });
  });
}
