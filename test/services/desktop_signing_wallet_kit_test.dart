import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// These mock-only types belong to WalletKit's existing locked core dependency.
// ignore: depend_on_referenced_packages
import 'package:reown_core/events/i_events.dart';
// The mock storage type is supplied by the same locked core dependency.
// ignore: depend_on_referenced_packages
import 'package:reown_core/store/i_store.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/services/desktop_signing_wallet_kit.dart';

class _Core extends Mock implements IReownCore {}

class _Store extends Mock implements IStore<Map<String, dynamic>> {}

class _Events extends Mock implements IEvents {}

class _Sign extends Mock implements IReownSign {}

class _ControlledKit extends DesktopSigningWalletKit {
  _ControlledKit(IReownCore core, this.sign)
    : super(
        core: core,
        metadata: const PairingMetadata(
          name: 'Synthetic desktop wallet',
          description: 'Offline initialization fixture',
          url: 'https://example.invalid',
        ),
      );

  final IReownSign sign;

  @override
  IReownSign get reOwnSign => sign;
}

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  late _Core core;
  late _Events events;
  late _Sign sign;
  late _ControlledKit kit;
  late List<String> order;
  late int paymentCalls;

  setUp(() {
    core = _Core();
    events = _Events();
    sign = _Sign();
    order = <String>[];
    paymentCalls = 0;
    when(() => core.storage).thenReturn(_Store());
    when(() => core.events).thenReturn(events);
    when(() => core.projectId).thenReturn('synthetic-project-id');
    when(() => core.start()).thenAnswer((_) async => order.add('core'));
    when(() => events.sendStoredEvents()).thenAnswer((_) async {
      order.add('events');
    });
    when(() => sign.init()).thenAnswer((_) async => order.add('sign'));
    kit = _ControlledKit(core, sign);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('walletconnect_pay'),
      (_) async {
        paymentCalls++;
        throw MissingPluginException('Synthetic unsupported desktop channel');
      },
    );
  });

  tearDown(() {
    binding.removeObserver(kit);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('walletconnect_pay'),
      null,
    );
  });

  test(
    'initializes signing with no desktop payment channel invocation',
    () async {
      await kit.init();
      await kit.init();
      expect(order, <String>['core', 'events', 'sign']);
      expect(paymentCalls, 0);
      expect(() => kit.pay, throwsUnsupportedError);
      verify(() => core.start()).called(1);
      verify(() => sign.init()).called(1);
    },
  );

  test(
    'concurrent initialization waits for the same signing operation',
    () async {
      final Completer<void> started = Completer<void>();
      final Completer<void> release = Completer<void>();
      when(() => sign.init()).thenAnswer((_) {
        started.complete();
        return release.future;
      });
      final Future<void> first = kit.init();
      await started.future;
      final Future<void> second = kit.init();
      expect(identical(first, second), isTrue);
      release.complete();
      await Future.wait(<Future<void>>[first, second]);
      expect(paymentCalls, 0);
      verify(() => sign.init()).called(1);
    },
  );

  test('failed signing initialization remains retryable', () async {
    int attempts = 0;
    when(() => sign.init()).thenAnswer((_) async {
      if (++attempts == 1) throw StateError('Synthetic signing failure');
    });
    await expectLater(kit.init(), throwsStateError);
    await kit.init();
    await kit.init();
    expect(attempts, 2);
    expect(paymentCalls, 0);
    verify(() => core.start()).called(2);
  });

  test(
    'core failure prevents events and signing from becoming ready',
    () async {
      when(() => core.start()).thenThrow(StateError('Synthetic core failure'));
      await expectLater(kit.init(), throwsStateError);
      verifyNever(() => events.sendStoredEvents());
      verifyNever(() => sign.init());
      expect(paymentCalls, 0);
    },
  );
}
