import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_walletkit/reown_walletkit.dart' hide Address;
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockWeb3WalletService extends Mock implements IWeb3WalletService {}

SessionData _buildActiveSession({
  required String topic,
  String chainId = 'zenon:1',
}) {
  return SessionData(
    topic: topic,
    pairingTopic: 'pairing-$topic',
    relay: Relay(ReownConstants.RELAYER_DEFAULT_PROTOCOL),
    expiry: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    acknowledged: true,
    controller: 'controller-key',
    namespaces: <String, Namespace>{
      'zenon': Namespace(
        chains: <String>[chainId],
        accounts: <String>['$chainId:z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7'],
        methods: const <String>['znn_info', 'znn_sign', 'znn_send'],
        events: const <String>['chainIdChange', 'addressChange'],
      ),
    },
    self: const ConnectionMetadata(
      publicKey: 'self-key',
      metadata: PairingMetadata(
        name: 's y r i u s',
        description: 'Zenon wallet',
        url: 'https://zenon.network',
      ),
    ),
    peer: const ConnectionMetadata(
      publicKey: 'peer-key',
      metadata: PairingMetadata(
        name: 'Test dApp',
        description: 'dApp',
        url: 'https://example.invalid',
      ),
    ),
  );
}

void main() {
  group('NoMService', () {
    const String ownedActive = 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
    const String ownedSecondary = 'z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz';
    const String foreignAddress = 'z1qxemdeddedxt0kenxxxxxxxxxxxxxxxxh9amk0';

    late _MockWeb3WalletService web3WalletService;
    late NoMService nomService;
    late Map<String, String> previousAddressMap;
    late List<String?> previousAddressList;
    late int previousChainId;

    setUp(() {
      previousAddressMap = Map<String, String>.from(kAddressLabelMap);
      previousAddressList = List<String?>.from(kDefaultAddressList);
      previousChainId = getChainIdentifier();
      setChainIdentifier();
      kAddressLabelMap = <String, String>{ownedActive: 'Address 1'};
      kDefaultAddressList = <String?>[ownedActive, ownedSecondary];

      web3WalletService = _MockWeb3WalletService();
      when(
        () => web3WalletService.getActiveSessions(),
      ).thenReturn(<String, SessionData>{});
      when(
        () => web3WalletService.getPendingSessionRequests(),
      ).thenReturn(<String, SessionRequest>{});

      nomService = NoMService(
        reference: NoMChainId.mainnet,
        web3WalletService: web3WalletService,
      );
    });

    tearDown(() {
      kAddressLabelMap = previousAddressMap;
      kDefaultAddressList = previousAddressList;
      setChainIdentifier(chainIdentifier: previousChainId);
    });

    group('client lifecycle safety', () {
      test('constructs without dereferencing client when WalletConnect is '
          'disabled and fails cleanly on session lookup', () {
        final Web3WalletService uncreatedService = Web3WalletService();
        addTearDown(uncreatedService.onDispose);

        final NoMService service = NoMService(
          reference: NoMChainId.mainnet,
          web3WalletService: uncreatedService,
        );

        expect(
          () => service.sessionByTopicForTesting('missing-topic'),
          throwsA(
            isA<ReownCoreError>().having(
              (ReownCoreError e) => e.code,
              'code',
              5001,
            ),
          ),
        );
      });
    });

    group('resolveSignMessage & encodeSignedMessagePayload', () {
      test('accepts plain non-empty String and Map with String message', () {
        expect(NoMService.resolveSignMessage('hello zenon'), 'hello zenon');
        expect(
          NoMService.resolveSignMessage(<String, dynamic>{
            'message': 'sign me',
            'fromAddress': ownedActive,
          }),
          'sign me',
        );
      });

      test('rejects missing, empty, or non-string message parameters', () {
        final List<dynamic> invalidInputs = <dynamic>[
          null,
          '',
          123,
          <String>['hello'],
          <String, dynamic>{},
          <String, dynamic>{'message': null},
          <String, dynamic>{'message': ''},
          <String, dynamic>{'message': 42},
        ];

        for (final dynamic input in invalidInputs) {
          expect(
            () => NoMService.resolveSignMessage(input),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                5003,
              ),
            ),
            reason: 'Expected input $input to be rejected',
          );
        }
      });

      test('domain-separates signed message bytes using UTF-8 byte length', () {
        const String ascii = 'hello';
        final Uint8List asciiPayload = NoMService.encodeSignedMessagePayload(
          ascii,
        );
        expect(
          asciiPayload,
          equals(utf8.encode('\x19Zenon Signed Message:\n5\nhello')),
        );

        // Even when total encoded payload length happens to be 32 bytes
        // (7-byte ASCII message), the fixed 25-byte domain prefix makes a
        // collision with a SHA3-256 account-block hash computationally
        // infeasible (200 fixed prefix bits).
        const String sevenBytes = '1234567';
        final Uint8List sevenBytePayload =
            NoMService.encodeSignedMessagePayload(sevenBytes);
        expect(sevenBytePayload.length, 32);
        expect(
          sevenBytePayload,
          equals(utf8.encode('\x19Zenon Signed Message:\n7\n1234567')),
        );
        expect(
          utf8.decode(sevenBytePayload.sublist(0, 25)),
          '\x19Zenon Signed Message:\n7\n',
        );

        // 32 CJK ideographs (96 UTF-8 bytes) must use UTF-8 encoding and
        // domain prefix so they can never forge a 32-byte account-block hash.
        final String cjk32 = String.fromCharCodes(
          List<int>.generate(32, (int i) => 0x4E00 + i),
        );
        final Uint8List cjkPayload = NoMService.encodeSignedMessagePayload(
          cjk32,
        );
        final List<int> expectedBody = utf8.encode(cjk32);
        expect(expectedBody.length, 96);
        expect(
          cjkPayload,
          equals(<int>[
            ...utf8.encode('\x19Zenon Signed Message:\n96\n'),
            ...expectedBody,
          ]),
        );
      });
    });

    group('validateSendAccountBlock & inspectSendAccountBlockData', () {
      test(
        'accepts valid userSend block matching active and session chain',
        () {
          final AccountBlockTemplate validSend = AccountBlockTemplate.send(
            Address.parse(ownedSecondary),
            znnZts,
            BigInt.from(100000000),
          );
          expect(
            () => nomService.validateSendAccountBlock(validSend),
            returnsNormally,
          );
        },
      );

      test(
        'rejects non-userSend, non-empty fromBlockHash, or chain mismatch',
        () {
          final String nonZeroHashA = 'a' * 64;
          final String nonZeroHashB = 'b' * 64;
          final AccountBlockTemplate receiveBlock =
              AccountBlockTemplate.receive(Hash.parse(nonZeroHashA));
          expect(
            () => nomService.validateSendAccountBlock(receiveBlock),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                5003,
              ),
            ),
          );

          final AccountBlockTemplate wrongFromBlockHash =
              AccountBlockTemplate.send(
                Address.parse(ownedSecondary),
                znnZts,
                BigInt.one,
              )..fromBlockHash = Hash.parse(nonZeroHashB);
          expect(
            () => nomService.validateSendAccountBlock(wrongFromBlockHash),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                5003,
              ),
            ),
          );

          final AccountBlockTemplate wrongBlockChain =
              AccountBlockTemplate.send(
                Address.parse(ownedSecondary),
                znnZts,
                BigInt.one,
              )..chainIdentifier = 3;
          expect(
            () => nomService.validateSendAccountBlock(wrongBlockChain),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                5003,
              ),
            ),
          );

          // Wallet switched to testnet while session is bound to mainnet.
          setChainIdentifier(chainIdentifier: 3);
          final AccountBlockTemplate testnetSend = AccountBlockTemplate.send(
            Address.parse(ownedSecondary),
            znnZts,
            BigInt.one,
          );
          expect(
            () => nomService.validateSendAccountBlock(testnetSend),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                5003,
              ),
            ),
          );
        },
      );

      test('decodes embedded contract calldata and flags raw payloads', () {
        final AccountBlockTemplate plainSend = AccountBlockTemplate.send(
          Address.parse(ownedSecondary),
          znnZts,
          BigInt.from(10),
        );
        final WalletConnectBlockDataInspection plainInfo =
            NoMService.inspectSendAccountBlockData(plainSend);
        expect(plainInfo.hasData, isFalse);
        expect(plainInfo.decodedBlockData, isNull);

        final List<int> delegateData = Definitions.pillar.encodeFunction(
          'Delegate',
          <dynamic>['MyPillar'],
        );
        final AccountBlockTemplate delegateCall =
            AccountBlockTemplate.callContract(
              pillarAddress,
              znnZts,
              BigInt.zero,
              delegateData,
            );
        final WalletConnectBlockDataInspection delegateInfo =
            NoMService.inspectSendAccountBlockData(delegateCall);
        expect(delegateInfo.hasData, isTrue);
        expect(delegateInfo.isEmbeddedContract, isTrue);
        expect(delegateInfo.contractName, 'Pillar');
        expect(delegateInfo.decodedBlockData?.function, 'Delegate');
        expect(
          delegateInfo.decodedBlockData?.params,
          equals(<String, dynamic>{'name': 'MyPillar'}),
        );

        final List<int> collectRewardData = Definitions.common.encodeFunction(
          'CollectReward',
          <dynamic>[],
        );
        final AccountBlockTemplate collectCall =
            AccountBlockTemplate.callContract(
              pillarAddress,
              znnZts,
              BigInt.zero,
              collectRewardData,
            );
        final WalletConnectBlockDataInspection collectInfo =
            NoMService.inspectSendAccountBlockData(collectCall);
        expect(collectInfo.decodedBlockData?.function, 'CollectReward');

        final AccountBlockTemplate rawUserData = AccountBlockTemplate.send(
          Address.parse(ownedSecondary),
          znnZts,
          BigInt.zero,
          const <int>[0xde, 0xad, 0xbe, 0xef],
        );
        final WalletConnectBlockDataInspection rawInfo =
            NoMService.inspectSendAccountBlockData(rawUserData);
        expect(rawInfo.hasData, isTrue);
        expect(rawInfo.isEmbeddedContract, isFalse);
        expect(rawInfo.decodedBlockData, isNull);
        expect(rawInfo.rawByteLength, 4);
        expect(rawInfo.rawHexPreview, '0xdeadbeef');
      });
    });

    group('revalidateInteractiveRequest', () {
      test(
        'succeeds while session is active, request is pending, and chain '
        'matches; rejects expired request, closed session, or changed chain',
        () {
          final SessionData activeSession = _buildActiveSession(
            topic: 'topic-live',
          );
          const SessionRequest pendingRequest = SessionRequest(
            id: 55,
            topic: 'topic-live',
            method: 'znn_send',
            chainId: 'zenon:1',
            params: <String, dynamic>{},
            verifyContext: VerifyContext(
              origin: 'https://example.invalid',
              validation: Validation.VALID,
              verifyUrl: '',
            ),
          );
          when(
            () => web3WalletService.getActiveSessions(),
          ).thenReturn(<String, SessionData>{'topic-live': activeSession});
          when(
            () => web3WalletService.getPendingSessionRequests(),
          ).thenReturn(<String, SessionRequest>{'55': pendingRequest});

          expect(
            () => nomService.revalidateInteractiveRequest(
              topic: 'topic-live',
              requestId: 55,
              requireActiveChainMatch: true,
            ),
            returnsNormally,
          );

          // Request expired / removed from pending store.
          when(
            () => web3WalletService.getPendingSessionRequests(),
          ).thenReturn(<String, SessionRequest>{});
          expect(
            () => nomService.revalidateInteractiveRequest(
              topic: 'topic-live',
              requestId: 55,
              requireActiveChainMatch: true,
            ),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                5005,
              ),
            ),
          );

          // Restore pending request, then switch active chain.
          when(
            () => web3WalletService.getPendingSessionRequests(),
          ).thenReturn(<String, SessionRequest>{'55': pendingRequest});
          setChainIdentifier(chainIdentifier: 3);
          expect(
            () => nomService.revalidateInteractiveRequest(
              topic: 'topic-live',
              requestId: 55,
              requireActiveChainMatch: true,
            ),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                5003,
              ),
            ),
          );

          // Session disconnected while dialog was open.
          setChainIdentifier();
          when(
            () => web3WalletService.getActiveSessions(),
          ).thenReturn(<String, SessionData>{});
          expect(
            () => nomService.revalidateInteractiveRequest(
              topic: 'topic-live',
              requestId: 55,
              requireActiveChainMatch: true,
            ),
            throwsA(
              isA<ReownCoreError>().having(
                (ReownCoreError e) => e.code,
                'code',
                5001,
              ),
            ),
          );
        },
      );
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
