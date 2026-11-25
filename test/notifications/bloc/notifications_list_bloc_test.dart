import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  group('NotificationsListBloc', () {
    late _MockNotificationsRepository mockRepository;
    late StreamController<void> changesController;

    final StoredWalletNotification first = StoredWalletNotification(
      key: 0,
      notification: WalletNotification(
        title: 'Payment received',
        timestamp: 2000,
        details: 'Received 10 ZNN',
        type: NotificationType.paymentReceived,
      ),
    );
    final StoredWalletNotification second = StoredWalletNotification(
      key: 1,
      notification: WalletNotification(
        title: 'Payment sent',
        timestamp: 1000,
        details: 'Sent 5 ZNN',
        type: NotificationType.paymentSent,
      ),
    );

    setUp(() {
      mockRepository = _MockNotificationsRepository();
      changesController = StreamController<void>.broadcast();
      when(
        () => mockRepository.watchChanges(),
      ).thenAnswer((_) => changesController.stream);
      when(
        () => mockRepository.loadNotifications(),
      ).thenAnswer((_) async => <StoredWalletNotification>[first, second]);
      when(
        () => mockRepository.deleteNotification(any<dynamic>()),
      ).thenAnswer((_) async {});
      when(
        () => mockRepository.clearAllNotifications(),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await changesController.close();
    });

    test('initial state is NotificationsListInitial', () {
      final NotificationsListBloc bloc = NotificationsListBloc(
        repository: mockRepository,
      );
      addTearDown(bloc.close);
      expect(bloc.state, equals(const NotificationsListInitial()));
    });

    blocTest<NotificationsListBloc, NotificationsListState>(
      'emits [loading, populated] on NotificationsListStarted and reloads on '
      'watchChanges events',
      build: () => NotificationsListBloc(repository: mockRepository),
      act: (NotificationsListBloc bloc) async {
        bloc.add(const NotificationsListStarted());
        await Future<void>.delayed(Duration.zero);

        when(
          () => mockRepository.loadNotifications(),
        ).thenAnswer((_) async => <StoredWalletNotification>[first]);
        changesController.add(null);
      },
      wait: const Duration(milliseconds: 20),
      expect: () => <NotificationsListState>[
        const NotificationsListLoading(),
        NotificationsListPopulated(
          notifications: <StoredWalletNotification>[first, second],
        ),
        NotificationsListPopulated(
          notifications: <StoredWalletNotification>[first],
        ),
      ],
    );

    blocTest<NotificationsListBloc, NotificationsListState>(
      'emits [loading, populated] on NotificationsListRefreshRequested',
      build: () => NotificationsListBloc(repository: mockRepository),
      act: (NotificationsListBloc bloc) =>
          bloc.add(const NotificationsListRefreshRequested()),
      expect: () => <NotificationsListState>[
        const NotificationsListLoading(),
        NotificationsListPopulated(
          notifications: <StoredWalletNotification>[first, second],
        ),
      ],
    );

    blocTest<NotificationsListBloc, NotificationsListState>(
      'deletes a single notification and reloads remaining items',
      seed: () => NotificationsListPopulated(
        notifications: <StoredWalletNotification>[first, second],
      ),
      setUp: () {
        when(
          () => mockRepository.loadNotifications(),
        ).thenAnswer((_) async => <StoredWalletNotification>[second]);
      },
      build: () => NotificationsListBloc(repository: mockRepository),
      act: (NotificationsListBloc bloc) =>
          bloc.add(NotificationDeleteRequested(key: first.key)),
      expect: () => <NotificationsListState>[
        NotificationsListPopulated(
          notifications: <StoredWalletNotification>[second],
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteNotification(first.key)).called(1);
      },
    );

    blocTest<NotificationsListBloc, NotificationsListState>(
      'preserves list and increments errorNonce when delete fails repeatedly',
      seed: () => NotificationsListPopulated(
        notifications: <StoredWalletNotification>[first, second],
      ),
      setUp: () {
        when(
          () => mockRepository.deleteNotification(any<dynamic>()),
        ).thenThrow(Exception('disk error'));
      },
      build: () => NotificationsListBloc(repository: mockRepository),
      act: (NotificationsListBloc bloc) => bloc
        ..add(NotificationDeleteRequested(key: first.key))
        ..add(NotificationDeleteRequested(key: first.key)),
      expect: () => <dynamic>[
        isA<NotificationsListPopulated>()
            .having(
              (NotificationsListPopulated s) => s.notifications,
              'notifications',
              equals(<StoredWalletNotification>[first, second]),
            )
            .having(
              (NotificationsListPopulated s) => s.actionError,
              'actionError',
              equals(NotificationsListActionError.delete),
            )
            .having(
              (NotificationsListPopulated s) => s.errorNonce,
              'errorNonce',
              equals(1),
            ),
        isA<NotificationsListPopulated>()
            .having(
              (NotificationsListPopulated s) => s.actionError,
              'actionError',
              equals(NotificationsListActionError.delete),
            )
            .having(
              (NotificationsListPopulated s) => s.errorNonce,
              'errorNonce',
              equals(2),
            ),
      ],
      errors: () => <dynamic>[isA<Exception>(), isA<Exception>()],
    );

    blocTest<NotificationsListBloc, NotificationsListState>(
      'clears all notifications and reloads empty list',
      seed: () => NotificationsListPopulated(
        notifications: <StoredWalletNotification>[first, second],
      ),
      setUp: () {
        when(
          () => mockRepository.loadNotifications(),
        ).thenAnswer((_) async => const <StoredWalletNotification>[]);
      },
      build: () => NotificationsListBloc(repository: mockRepository),
      act: (NotificationsListBloc bloc) =>
          bloc.add(const NotificationsClearAllRequested()),
      expect: () => <NotificationsListState>[
        const NotificationsListPopulated(
          notifications: <StoredWalletNotification>[],
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.clearAllNotifications()).called(1);
      },
    );

    blocTest<NotificationsListBloc, NotificationsListState>(
      'preserves list and surfaces clearAll actionError when clear fails',
      seed: () => NotificationsListPopulated(
        notifications: <StoredWalletNotification>[first],
      ),
      setUp: () {
        when(
          () => mockRepository.clearAllNotifications(),
        ).thenThrow(Exception('clear error'));
      },
      build: () => NotificationsListBloc(repository: mockRepository),
      act: (NotificationsListBloc bloc) =>
          bloc.add(const NotificationsClearAllRequested()),
      expect: () => <dynamic>[
        isA<NotificationsListPopulated>()
            .having(
              (NotificationsListPopulated s) => s.notifications,
              'notifications',
              equals(<StoredWalletNotification>[first]),
            )
            .having(
              (NotificationsListPopulated s) => s.actionError,
              'actionError',
              equals(NotificationsListActionError.clearAll),
            )
            .having(
              (NotificationsListPopulated s) => s.errorNonce,
              'errorNonce',
              equals(1),
            ),
      ],
      errors: () => <dynamic>[isA<Exception>()],
    );

    blocTest<NotificationsListBloc, NotificationsListState>(
      'emits NotificationsListFailure when loading throws',
      setUp: () {
        when(
          () => mockRepository.loadNotifications(),
        ).thenThrow(Exception('read error'));
      },
      build: () => NotificationsListBloc(repository: mockRepository),
      act: (NotificationsListBloc bloc) =>
          bloc.add(const NotificationsListStarted()),
      expect: () => <dynamic>[
        const NotificationsListLoading(),
        isA<NotificationsListFailure>().having(
          (NotificationsListFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      errors: () => <dynamic>[isA<Exception>()],
    );

    test(
      're-attaches watchChanges on refresh after watch stream closes',
      () async {
        final StreamController<void> firstStream = StreamController<void>();
        final StreamController<void> secondStream = StreamController<void>();
        addTearDown(() async {
          await firstStream.close();
          await secondStream.close();
        });

        int watchCalls = 0;
        when(() => mockRepository.watchChanges()).thenAnswer((_) {
          watchCalls++;
          return watchCalls == 1 ? firstStream.stream : secondStream.stream;
        });

        final NotificationsListBloc bloc = NotificationsListBloc(
          repository: mockRepository,
        );
        addTearDown(bloc.close);

        bloc.add(const NotificationsListStarted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(watchCalls, 1);

        await firstStream.close();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        bloc.add(const NotificationsListRefreshRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(watchCalls, 2);

        when(
          () => mockRepository.loadNotifications(),
        ).thenAnswer((_) async => <StoredWalletNotification>[first]);
        secondStream.add(null);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          bloc.state,
          equals(
            NotificationsListPopulated(
              notifications: <StoredWalletNotification>[first],
            ),
          ),
        );
      },
    );

    test('coalesces burst watchChanges events into a single reload', () async {
      final Completer<List<StoredWalletNotification>> firstLoadCompleter =
          Completer<List<StoredWalletNotification>>();
      int loadCalls = 0;
      when(() => mockRepository.loadNotifications()).thenAnswer((_) {
        loadCalls++;
        if (loadCalls == 1) {
          return firstLoadCompleter.future;
        }
        return Future<List<StoredWalletNotification>>.value(
          const <StoredWalletNotification>[],
        );
      });

      final NotificationsListBloc bloc = NotificationsListBloc(
        repository: mockRepository,
      )..add(const NotificationsListStarted());
      addTearDown(bloc.close);

      await Future<void>.delayed(Duration.zero);

      // Emit a burst of 50 watch events (as Hive box.clear() does) while the
      // initial load is still running.
      for (int i = 0; i < 50; i++) {
        changesController.add(null);
      }

      firstLoadCompleter.complete(<StoredWalletNotification>[first, second]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Initial load + 1 coalesced reload (not 51).
      expect(loadCalls, equals(2));
      expect(
        bloc.state,
        equals(
          const NotificationsListPopulated(
            notifications: <StoredWalletNotification>[],
          ),
        ),
      );
    });

    test('cancels watch subscription when closed', () async {
      bool cancelled = false;
      final StreamController<void> trackedController = StreamController<void>(
        onCancel: () {
          cancelled = true;
        },
      );
      addTearDown(trackedController.close);
      when(
        () => mockRepository.watchChanges(),
      ).thenAnswer((_) => trackedController.stream);

      final NotificationsListBloc bloc = NotificationsListBloc(
        repository: mockRepository,
      )..add(const NotificationsListStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await bloc.close();
      expect(cancelled, isTrue);
    });
  });
}
