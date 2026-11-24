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

    test('retries across unconfirmed reads and transient errors', () async {
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
      expect(attempts, 3);
      expect(
        sleeps,
        <Duration>[
          kDefaultConfirmationPollInterval,
          kDefaultConfirmationPollInterval,
        ],
      );
    });

    test('clamps final sleep and returns false when timeout elapses', () async {
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
      expect(attempts, 4);
      expect(
        sleeps,
        <Duration>[
          const Duration(seconds: 3),
          const Duration(seconds: 3),
          const Duration(seconds: 1),
        ],
      );
    });

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
