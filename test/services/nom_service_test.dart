import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class _MockWeb3WalletService extends Mock implements IWeb3WalletService {}

class _MockReownWalletKit extends Mock implements ReownWalletKit {}

void main() {
  group('NoMService', () {
    const String ownedActive = 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
    const String ownedSecondary = 'z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz';
    const String foreignAddress = 'z1qxemdeddedxt0kenxxxxxxxxxxxxxxxxh9amk0';

    late _MockWeb3WalletService web3WalletService;
    late _MockReownWalletKit walletKit;
    late NoMService nomService;
    late Map<String, String> previousAddressMap;
    late List<String?> previousAddressList;

    setUp(() {
      previousAddressMap = Map<String, String>.from(kAddressLabelMap);
      previousAddressList = List<String?>.from(kDefaultAddressList);
      kAddressLabelMap = <String, String>{ownedActive: 'Address 1'};
      kDefaultAddressList = <String?>[ownedActive, ownedSecondary];

      web3WalletService = _MockWeb3WalletService();
      walletKit = _MockReownWalletKit();
      when(() => web3WalletService.getWeb3Wallet()).thenReturn(walletKit);

      nomService = NoMService(
        reference: NoMChainId.mainnet,
        web3WalletService: web3WalletService,
      );
    });

    tearDown(() {
      kAddressLabelMap = previousAddressMap;
      kDefaultAddressList = previousAddressList;
    });

    group('extractRequestedFromAddress', () {
      test('returns non-empty string fromAddress from Map params', () {
        expect(
          NoMService.extractRequestedFromAddress(<String, dynamic>{
            'fromAddress': ownedSecondary,
          }),
          ownedSecondary,
        );
      });

      test('returns null for missing, empty, or non-map params', () {
        expect(NoMService.extractRequestedFromAddress(null), isNull);
        expect(NoMService.extractRequestedFromAddress('raw message'), isNull);
        expect(
          NoMService.extractRequestedFromAddress(<String, dynamic>{}),
          isNull,
        );
        expect(
          NoMService.extractRequestedFromAddress(<String, dynamic>{
            'fromAddress': '',
          }),
          isNull,
        );
        expect(
          NoMService.extractRequestedFromAddress(<String, dynamic>{
            'fromAddress': 123,
          }),
          isNull,
        );
      });
    });

    group('resolveSignerAddress', () {
      test(
        'falls back to activeAddress when requestedFromAddress is absent',
        () {
          expect(
            nomService.resolveSignerAddress(
              activeAddress: ownedActive,
              requestedFromAddress: null,
              method: 'znn_sign',
              topic: 'topic-1',
            ),
            ownedActive,
          );
          expect(
            nomService.resolveSignerAddress(
              activeAddress: ownedActive,
              requestedFromAddress: '',
              method: 'znn_send',
              topic: 'topic-1',
            ),
            ownedActive,
          );
        },
      );

      test(
        'accepts wallet-owned addresses from map or default address list',
        () {
          expect(
            nomService.resolveSignerAddress(
              activeAddress: ownedActive,
              requestedFromAddress: ownedActive,
              method: 'znn_sign',
              topic: 'topic-1',
            ),
            ownedActive,
          );
          expect(
            nomService.resolveSignerAddress(
              activeAddress: ownedActive,
              requestedFromAddress: ownedSecondary,
              method: 'znn_send',
              topic: 'topic-1',
            ),
            ownedSecondary,
          );
        },
      );

      test(
        'rejects non-wallet-owned fromAddress with UNSUPPORTED_ACCOUNTS',
        () {
          expect(
            () => nomService.resolveSignerAddress(
              activeAddress: ownedActive,
              requestedFromAddress: foreignAddress,
              method: 'znn_send',
              topic: 'topic-1',
            ),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                Errors.getSdkError(Errors.UNSUPPORTED_ACCOUNTS).code,
              ),
            ),
          );
        },
      );
    });

    group('single-flight request execution', () {
      test('deduplicates concurrent calls sharing the same key', () async {
        int invocations = 0;
        final Completer<String> completer = Completer<String>();

        final Future<dynamic> first = nomService.runSingleFlightForTesting(
          'znn_sign:topic-1:#1',
          () {
            invocations++;
            return completer.future;
          },
        );
        final Future<dynamic> second = nomService.runSingleFlightForTesting(
          'znn_sign:topic-1:#1',
          () {
            invocations++;
            return Future<String>.value('unexpected');
          },
        );

        expect(identical(first, second), isTrue);
        completer.complete('signed-hex');
        expect(await first, 'signed-hex');
        expect(await second, 'signed-hex');
        expect(invocations, 1);
      });

      test(
        'cleans up key on error without reporting an unhandled zone error',
        () async {
          final List<Object> unhandledErrors = <Object>[];

          await runZonedGuarded(
            () async {
              await expectLater(
                nomService.runSingleFlightForTesting(
                  'znn_sign:topic-1:#99',
                  () async => throw StateError('user rejected'),
                ),
                throwsA(isA<StateError>()),
              );

              // Allow any scheduled microtasks to settle so an unhandled
              // async error from a detached future would surface here.
              await Future<void>.delayed(Duration.zero);

              // Subsequent request with the same key executes cleanly again.
              final dynamic retryResult = await nomService
                  .runSingleFlightForTesting(
                    'znn_sign:topic-1:#99',
                    () async => 'retry-ok',
                  );
              expect(retryResult, 'retry-ok');
            },
            (Object error, StackTrace stackTrace) {
              unhandledErrors.add(error);
            },
          );

          expect(unhandledErrors, isEmpty);
        },
      );
    });
  });
}
