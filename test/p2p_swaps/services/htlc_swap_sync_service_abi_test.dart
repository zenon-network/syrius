import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockHtlcSwapRepository extends Mock implements HtlcSwapRepository {}

class _MockHtlcSwapAutoUnlockService extends Mock
    implements HtlcSwapAutoUnlockService {}

class _MockZenon extends Mock implements Zenon {}

class _MockWsClient extends Mock implements WsClient {}

class _MockLedgerApi extends Mock implements LedgerApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(<P2pSwapState>[]);
    registerFallbackValue(<HtlcSwap>[]);
    registerFallbackValue(emptyAddress);
  });

  group('HtlcSwapSyncService ABI BigInt decoding', () {
    late _MockHtlcSwapRepository swapRepository;
    late _MockHtlcSwapAutoUnlockService autoUnlockService;
    late _MockZenon zenon;
    late _MockWsClient wsClient;
    late _MockLedgerApi ledgerApi;
    late HtlcSwapSyncService syncService;
    late Zenon? previousAppZenon;

    final Address initiatorAddress = Address.fromPublicKey(
      List<int>.filled(32, 1),
    );
    final Address counterpartyAddress = Address.fromPublicKey(
      List<int>.filled(32, 2),
    );
    final List<int> preimage = List<int>.filled(32, 7);
    final Hash hashLock = Hash.digest(preimage);
    final Hash initialHtlcId = Hash.digest(List<int>.filled(32, 11));
    final Hash counterHtlcId = Hash.digest(List<int>.filled(32, 22));

    setUp(() {
      previousAppZenon = app.zenon;
      swapRepository = _MockHtlcSwapRepository();
      autoUnlockService = _MockHtlcSwapAutoUnlockService();
      zenon = _MockZenon();
      wsClient = _MockWsClient();
      ledgerApi = _MockLedgerApi();

      when(() => zenon.wsClient).thenReturn(wsClient);
      when(() => zenon.ledger).thenReturn(ledgerApi);
      when(wsClient.isClosed).thenReturn(false);
      when(() => autoUnlockService.unlockNext(any())).thenAnswer((_) async {});

      app.zenon = zenon;
      syncService = HtlcSwapSyncService(
        swapRepository: swapRepository,
        autoUnlockService: autoUnlockService,
        zenon: zenon,
      );
    });

    tearDown(() async {
      await syncService.stop();
      app.zenon = previousAppZenon;
    });

    test('detects counter-HTLC from real ABI-encoded Create block with BigInt '
        'hashType and expirationTime', () async {
      const int now = 1795742000;
      const int counterExpiration = now + 3600;
      const int chainId = 69;
      final BigInt counterAmount = BigInt.from(15000000);

      final HtlcSwap activeOutgoingSwap = HtlcSwap(
        id: initialHtlcId.toString(),
        chainId: chainId,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.outgoing,
        selfAddress: initiatorAddress.toString(),
        counterpartyAddress: counterpartyAddress.toString(),
        state: P2pSwapState.active,
        startTime: now - 10,
        initialHtlcId: initialHtlcId.toString(),
        initialHtlcExpirationTime: now + 28800,
        fromAmount: BigInt.from(25000000),
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        hashLock: hashLock.toString(),
        preimage: FormatUtils.encodeHexString(preimage),
        hashType: htlcHashTypeSha3,
      );

      // Encode Create ABI payload using the real znn_sdk_dart Definitions.htlc
      // so AccountBlockUtils.getDecodedBlockData returns BigInt for uint8
      // hashType and int64 expirationTime.
      final List<int> encodedCreateData = Definitions.htlc
          .encodeFunction('Create', <dynamic>[
            initiatorAddress,
            counterExpiration,
            htlcHashTypeSha3,
            htlcPreimageMaxLength,
            hashLock.getBytes(),
          ]);

      final AccountBlock pairedSendBlock = AccountBlock.fromJson(
        <String, dynamic>{
          'version': 1,
          'chainIdentifier': chainId,
          'blockType': BlockTypeEnum.userSend.index,
          'hash': counterHtlcId.toString(),
          'previousHash': emptyHash.toString(),
          'height': 2,
          'momentumAcknowledged': <String, dynamic>{
            'hash': emptyHash.toString(),
            'height': 10,
          },
          'address': counterpartyAddress.toString(),
          'toAddress': htlcAddress.toString(),
          'amount': counterAmount.toString(),
          'tokenStandard': znnZts.toString(),
          'fromBlockHash': emptyHash.toString(),
          'descendantBlocks': const <dynamic>[],
          'data': BytesUtils.bytesToBase64(encodedCreateData),
          'fusedPlasma': 0,
          'difficulty': 0,
          'nonce': '0000000000000000',
          'basePlasma': 0,
          'usedPlasma': 0,
          'changesHash': emptyHash.toString(),
          'token': kZnnCoin.toJson(),
        },
      );

      final AccountBlock htlcReceiveBlock = AccountBlock.fromJson(
        <String, dynamic>{
          'version': 1,
          'chainIdentifier': chainId,
          'blockType': BlockTypeEnum.contractReceive.index,
          'hash': Hash.digest(List<int>.filled(32, 33)).toString(),
          'previousHash': emptyHash.toString(),
          'height': 2,
          'momentumAcknowledged': <String, dynamic>{
            'hash': emptyHash.toString(),
            'height': 11,
          },
          'address': htlcAddress.toString(),
          'toAddress': emptyAddress.toString(),
          'amount': '0',
          'tokenStandard': emptyTokenStandard,
          'fromBlockHash': counterHtlcId.toString(),
          'descendantBlocks': const <dynamic>[],
          'data': '',
          'fusedPlasma': 0,
          'difficulty': 0,
          'nonce': '0000000000000000',
          'basePlasma': 0,
          'usedPlasma': 0,
          'changesHash': emptyHash.toString(),
          'confirmationDetail': <String, dynamic>{
            'numConfirmations': 1,
            'momentumHeight': 12,
            'momentumHash': emptyHash.toString(),
            'momentumTimestamp': now,
          },
          'pairedAccountBlock': pairedSendBlock.toJson(),
        },
      );

      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) async => <HtlcSwap>[activeOutgoingSwap]);
      when(
        () => swapRepository.getLastCheckedHtlcBlockHeight(),
      ).thenAnswer((_) async => 0);
      when(
        () => swapRepository.getSwapByHashLock(hashLock.toString()),
      ).thenAnswer((_) async => activeOutgoingSwap);
      when(
        () => ledgerApi.getFrontierAccountBlock(htlcAddress),
      ).thenAnswer((_) async => htlcReceiveBlock);
      when(
        () => ledgerApi.getAccountBlocksByPage(
          htlcAddress,
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => AccountBlockList(
          list: <AccountBlock>[htlcReceiveBlock],
          count: 1,
          more: false,
        ),
      );

      final Completer<HtlcSwap?> processedSwapCompleter =
          Completer<HtlcSwap?>();
      when(
        () => swapRepository.storeProcessedHtlcBlock(
          height: 2,
          updatedSwap: any(named: 'updatedSwap'),
        ),
      ).thenAnswer((Invocation invocation) async {
        final HtlcSwap? updated =
            invocation.namedArguments[#updatedSwap] as HtlcSwap?;
        if (!processedSwapCompleter.isCompleted) {
          processedSwapCompleter.complete(updated);
        }
      });

      syncService.start();
      final HtlcSwap? updatedSwap = await processedSwapCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      await syncService.stop();

      expect(updatedSwap, isNotNull);
      expect(updatedSwap!.counterHtlcId, counterHtlcId.toString());
      expect(updatedSwap.toAmount, counterAmount);
      expect(updatedSwap.toToken?.tokenStandard, znnZts);
      expect(updatedSwap.counterHtlcExpirationTime, counterExpiration);
    });
  });
}
