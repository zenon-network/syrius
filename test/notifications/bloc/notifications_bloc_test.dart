import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/hive/hive_registrar.g.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _FakeWalletNotification extends Fake implements WalletNotification {}

class _RecordingBlocObserver extends BlocObserver {
  final List<Object> errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  late Directory hiveDirectory;

  setUpAll(() {
    registerFallbackValue(_FakeWalletNotification());
    hiveDirectory = Directory.systemTemp.createTempSync(
      'syrius_notifications_bloc_test_',
    );
    Hive
      ..init(hiveDirectory.path)
      ..registerAdapters();
  });

  tearDown(() async {
    if (Hive.isBoxOpen(kNotificationsBox)) {
      await Hive.box<dynamic>(kNotificationsBox).clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  WalletNotification buildNotification({
    String title = 'Swap started',
    int timestamp = 1000,
    String details = 'Hash: 123',
    NotificationType type = NotificationType.paymentSent,
  }) => WalletNotification(
    title: title,
    timestamp: timestamp,
    details: details,
    type: type,
  );

  group('NotificationsBloc (Hive integration)', () {
    test(
      'recordNotification stores history without publishing a banner state',
      () async {
        final NotificationsBloc bloc = NotificationsBloc(
          isDesktopPlatformCheck: () => false,
        );
        addTearDown(bloc.close);

        final List<NotificationsState> states = <NotificationsState>[];
        final StreamSubscription<NotificationsState> subscription = bloc.stream
            .listen(states.add);
        addTearDown(subscription.cancel);

        final WalletNotification notification = buildNotification();
        await bloc.recordNotification(notification);
        await Future<void>.delayed(Duration.zero);

        final Box<dynamic> box = Hive.box<dynamic>(kNotificationsBox);
        final WalletNotification stored =
            box.values.single as WalletNotification;
        expect(stored.title, notification.title);
        expect(stored.timestamp, notification.timestamp);
        expect(stored.details, notification.details);
        expect(stored.type, notification.type);
        expect(states, isEmpty);
        expect(bloc.state.hasActiveNotification, isFalse);
      },
    );

    test(
      'addNotification stores history and emits active banner state',
      () async {
        final List<WalletNotification> desktopShown = <WalletNotification>[];
        final NotificationsBloc bloc = NotificationsBloc(
          isDesktopPlatformCheck: () => true,
          isDesktopNotificationsEnabled: () => true,
          showDesktopNotification: (WalletNotification n) async {
            desktopShown.add(n);
          },
        );
        addTearDown(bloc.close);

        final WalletNotification notification = buildNotification(
          title: 'Payment received',
          timestamp: 2000,
          type: NotificationType.paymentReceived,
        );
        await bloc.addNotification(notification);

        final Box<dynamic> box = Hive.box<dynamic>(kNotificationsBox);
        expect(box.length, 1);
        expect(desktopShown, hasLength(1));
        expect(desktopShown.single.title, 'Payment received');
        expect(bloc.state.hasActiveNotification, isTrue);
        expect(bloc.state.activeNotification?.title, 'Payment received');
        expect(bloc.state.revision, 1);
      },
    );

    test(
      'addNotification(null) clears active banner without writing null to Hive',
      () async {
        final NotificationsBloc bloc = NotificationsBloc(
          isDesktopPlatformCheck: () => false,
        );
        addTearDown(bloc.close);

        await bloc.addNotification(buildNotification(title: 'First'));
        expect(bloc.state.hasActiveNotification, isTrue);

        await bloc.addNotification(null);
        expect(bloc.state.hasActiveNotification, isFalse);
        expect(bloc.state.activeNotification, isNull);
        expect(bloc.state.revision, 1);

        final Box<dynamic> box = Hive.box<dynamic>(kNotificationsBox);
        expect(box.length, 1);
        expect(
          box.values.every((dynamic v) => v is WalletNotification),
          isTrue,
        );
      },
    );
  });

  group('NotificationsBloc (unit)', () {
    late _MockNotificationsRepository repository;

    setUp(() {
      repository = _MockNotificationsRepository();
      when(
        () => repository.addNotification(
          any(),
          maxEntries: any(named: 'maxEntries'),
        ),
      ).thenAnswer((_) async {});
    });

    blocTest<NotificationsBloc, NotificationsState>(
      'emits incremented revision for consecutive identical notifications and '
      'clears on dismiss',
      build: () => NotificationsBloc(
        repository: repository,
        isDesktopPlatformCheck: () => false,
      ),
      act: (NotificationsBloc bloc) async {
        final WalletNotification n = buildNotification(
          title: 'Repeated',
          timestamp: 42,
        );
        await bloc.addNotification(n);
        await bloc.addNotification(n);
        await bloc.dismissNotification();
      },
      expect: () => <NotificationsState>[
        NotificationsState(
          activeNotification: buildNotification(
            title: 'Repeated',
            timestamp: 42,
          ),
          revision: 1,
        ),
        NotificationsState(
          activeNotification: buildNotification(
            title: 'Repeated',
            timestamp: 42,
          ),
          revision: 2,
        ),
        const NotificationsState(revision: 2),
      ],
    );

    test(
      'still emits in-app banner when desktop notification plugin throws',
      () async {
        final BlocObserver previousObserver = Bloc.observer;
        final _RecordingBlocObserver observer = _RecordingBlocObserver();
        Bloc.observer = observer;
        addTearDown(() => Bloc.observer = previousObserver);

        final NotificationsBloc bloc = NotificationsBloc(
          repository: repository,
          isDesktopPlatformCheck: () => true,
          isDesktopNotificationsEnabled: () => true,
          showDesktopNotification: (_) async {
            throw StateError('DBus unavailable');
          },
        );
        addTearDown(bloc.close);

        await bloc.addNotification(buildNotification(title: 'Still visible'));

        expect(bloc.state.hasActiveNotification, isTrue);
        expect(bloc.state.activeNotification?.title, 'Still visible');
        expect(observer.errors, contains(isA<StateError>()));
      },
    );

    test(
      'does not emit banner when repository persistence fails',
      () async {
        final BlocObserver previousObserver = Bloc.observer;
        final _RecordingBlocObserver observer = _RecordingBlocObserver();
        Bloc.observer = observer;
        addTearDown(() => Bloc.observer = previousObserver);

        when(
          () => repository.addNotification(
            any(),
            maxEntries: any(named: 'maxEntries'),
          ),
        ).thenThrow(Exception('disk full'));

        final NotificationsBloc bloc = NotificationsBloc(
          repository: repository,
          isDesktopPlatformCheck: () => false,
        );
        addTearDown(bloc.close);

        await bloc.addNotification(buildNotification(title: 'Failed'));

        expect(bloc.state.hasActiveNotification, isFalse);
        expect(observer.errors, contains(isA<Exception>()));
      },
    );

    test(
      'helper methods create expected notification payloads',
      () async {
        final List<WalletNotification> stored = <WalletNotification>[];
        when(
          () => repository.addNotification(
            any(),
            maxEntries: any(named: 'maxEntries'),
          ),
        ).thenAnswer((Invocation invocation) async {
          stored.add(
            invocation.positionalArguments.first as WalletNotification,
          );
        });

        final DateTime fixedTime = DateTime.fromMillisecondsSinceEpoch(123456);
        final NotificationsBloc bloc = NotificationsBloc(
          repository: repository,
          isDesktopPlatformCheck: () => false,
          now: () => fixedTime,
        );
        addTearDown(bloc.close);

        await bloc.sendPlasmaNotification('send ZNN');
        await bloc.addErrorNotification('boom', 'Send failed');
        await bloc.recordErrorNotification('silent boom', 'Background error');

        expect(stored, hasLength(3));
        expect(
          stored[0].title,
          'Plasma will be generated in order to send ZNN',
        );
        expect(stored[0].type, NotificationType.generatingPlasma);
        expect(stored[0].timestamp, 123456);

        expect(stored[1].title, 'Send failed');
        expect(stored[1].details, 'Send failed: boom');
        expect(stored[1].type, NotificationType.error);

        expect(stored[2].title, 'Background error');
        expect(stored[2].details, 'Background error: silent boom');
        expect(stored[2].type, NotificationType.error);
        expect(bloc.state.activeNotification?.title, 'Send failed');
      },
    );

    test(
      'completes pending futures cleanly when closed mid-operation and ignores '
      'calls after close',
      () async {
        final Completer<void> blocker = Completer<void>();
        when(
          () => repository.addNotification(
            any(),
            maxEntries: any(named: 'maxEntries'),
          ),
        ).thenAnswer((_) => blocker.future);

        final NotificationsBloc bloc = NotificationsBloc(
          repository: repository,
          isDesktopPlatformCheck: () => false,
        );

        final Future<void> firstFuture = bloc.addNotification(
          buildNotification(title: 'First'),
        );
        final Future<void> queuedFuture = bloc.addNotification(
          buildNotification(title: 'Queued'),
        );

        final Future<void> closeFuture = bloc.close();
        blocker.complete();
        await Future.wait<void>(<Future<void>>[
          closeFuture,
          firstFuture,
          queuedFuture,
        ]);

        // Subsequent calls after close resolve immediately without throwing.
        await bloc.addNotification(buildNotification(title: 'After close'));
        await bloc.dismissNotification();
      },
    );
  });
}
