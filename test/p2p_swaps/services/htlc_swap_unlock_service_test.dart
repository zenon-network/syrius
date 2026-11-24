import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockEmbeddedApi extends Mock implements EmbeddedApi {}

class MockHtlcApi extends Mock implements HtlcApi {}

class MockZenon extends Mock implements Zenon {}

void main() {
  group('HtlcSwapUnlockService', () {
    const int now = 1000;
    final Hash initialHtlcId = Hash.digest(<int>[1, 2, 3]);
    final Hash counterHtlcId = Hash.digest(<int>[4, 5, 6]);
    final List<int> preimage = <int>[7, 8, 9];
    final Address selfAddress = emptyAddress;

    late MockAccountBlockUtils accountBlockUtils;
    late MockEmbeddedApi embeddedApi;
    late MockHtlcApi htlcApi;
    late MockZenon zenon;
    late AccountBlockTemplate transactionParams;
    late HtlcInfo htlc;
    late HtlcSwap swap;
    late HtlcSwapUnlockService service;
    late List<String?> previousDefaultAddressList;

    HtlcInfo buildHtlc({
      Hash? id,
      Address? hashLocked,
      List<int>? hashLock,
      int? expirationTime,
      int keyMaxSize = htlcPreimageMaxLength,
    }) => HtlcInfo(
      id: id ?? counterHtlcId,
      timeLocked: htlcAddress,
      hashLocked: hashLocked ?? selfAddress,
      tokenStandard: kQsrCoin.tokenStandard,
      amount: BigInt.one,
      expirationTime:
          expirationTime ?? now + kMinSafeTimeToCompleteSwap.inSeconds + 1,
      hashType: htlcHashTypeSha3,
      keyMaxSize: keyMaxSize,
      hashLock: hashLock ?? Hash.digest(preimage).getBytes()!,
    );

    setUp(() {
      previousDefaultAddressList = kDefaultAddressList;
      kDefaultAddressList = <String?>[selfAddress.toString()];
      accountBlockUtils = MockAccountBlockUtils();
      embeddedApi = MockEmbeddedApi();
      htlcApi = MockHtlcApi();
      zenon = MockZenon();
      transactionParams = AccountBlockTemplate(blockType: 1);
      htlc = buildHtlc();
      swap = HtlcSwap(
        hashLock: Hash.digest(preimage).toString(),
        initialHtlcId: initialHtlcId.toString(),
        initialHtlcExpirationTime: 2000,
        hashType: htlcHashTypeSha3,
        id: initialHtlcId.toString(),
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.outgoing,
        selfAddress: selfAddress.toString(),
        counterpartyAddress: htlcAddress.toString(),
        fromAmount: BigInt.one,
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: now,
        state: P2pSwapState.active,
        counterHtlcId: counterHtlcId.toString(),
        preimage: FormatUtils.encodeHexString(preimage),
      );

      when(() => zenon.embedded).thenReturn(embeddedApi);
      when(() => embeddedApi.htlc).thenReturn(htlcApi);
      when(() => htlcApi.getById(counterHtlcId)).thenAnswer((_) async => htlc);
      when(
        () => htlcApi.unlock(counterHtlcId, preimage),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'complete swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => transactionParams);

      service = HtlcSwapUnlockService(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        unixTimeProvider: () => now,
      );
    });

    tearDown(() {
      kDefaultAddressList = previousDefaultAddressList;
    });

    test('unlocks the counter HTLC for an outgoing swap', () async {
      final AccountBlockTemplate block = await service.unlock(swap);

      expect(block, transactionParams);
      verify(() => htlcApi.getById(counterHtlcId)).called(1);
      verify(() => htlcApi.unlock(counterHtlcId, preimage)).called(1);
      verify(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'complete swap',
          address: selfAddress,
          waitForRequiredPlasma: true,
        ),
      ).called(1);
    });

    test('unlocks the initial HTLC for an incoming swap', () async {
      swap = swap.copyWith(direction: P2pSwapDirection.incoming);
      htlc = buildHtlc(id: initialHtlcId);
      when(() => htlcApi.getById(initialHtlcId)).thenAnswer((_) async => htlc);
      when(
        () => htlcApi.unlock(initialHtlcId, preimage),
      ).thenReturn(transactionParams);

      await service.unlock(swap);

      verify(() => htlcApi.getById(initialHtlcId)).called(1);
      verify(() => htlcApi.unlock(initialHtlcId, preimage)).called(1);
    });

    test('rejects a swap without a funded HTLC', () async {
      swap = swap.copyWith(counterHtlcId: null);

      await expectLater(
        service.unlock(swap),
        throwsA(
          isA<SyriusException>().having(
            (SyriusException error) => error.message,
            'message',
            'Invalid swap',
          ),
        ),
      );

      verifyNever(() => htlcApi.getById(counterHtlcId));
    });

    test('rejects HTLC data that does not match the swap', () async {
      swap = swap.copyWith(hashLock: Hash.digest(<int>[10]).toString());

      await expectLater(
        service.unlock(swap),
        throwsA(
          isA<SyriusException>().having(
            (SyriusException error) => error.message,
            'message',
            'Invalid swap',
          ),
        ),
      );

      verifyNever(() => htlcApi.unlock(counterHtlcId, preimage));
    });

    test('rejects an HTLC address that is not owned by the wallet', () async {
      kDefaultAddressList = <String?>[];

      await expectLater(
        service.unlock(swap),
        throwsA(
          isA<SyriusException>().having(
            (SyriusException error) => error.message,
            'message',
            contains('Swap address not in default addresses'),
          ),
        ),
      );

      verifyNever(() => htlcApi.unlock(counterHtlcId, preimage));
    });

    test('rejects a swap at the safe expiration cutoff', () async {
      htlc = buildHtlc(
        expirationTime: now + kMinSafeTimeToCompleteSwap.inSeconds,
      );

      await expectLater(
        service.unlock(swap),
        throwsA(
          isA<SyriusException>().having(
            (SyriusException error) => error.message,
            'message',
            'The swap will expire too soon for a safe swap.',
          ),
        ),
      );

      verifyNever(() => htlcApi.unlock(counterHtlcId, preimage));
    });

    test('rejects a preimage that exceeds the HTLC key size', () async {
      htlc = buildHtlc(keyMaxSize: preimage.length - 1);

      await expectLater(
        service.unlock(swap),
        throwsA(
          isA<SyriusException>().having(
            (SyriusException error) => error.message,
            'message',
            'The swap secret size exceeds the maximum allowed size.',
          ),
        ),
      );

      verifyNever(() => htlcApi.unlock(counterHtlcId, preimage));
    });

    test(
      'rejects a malformed hex preimage without leaking the raw preimage',
      () async {
        const String malformedPreimage = 'zzzz-secret-preimage-leak';
        swap = swap.copyWith(preimage: malformedPreimage);

        await expectLater(
          service.unlock(swap),
          throwsA(
            isA<SyriusException>()
                .having(
                  (SyriusException error) => error.message,
                  'message',
                  'Invalid swap secret.',
                )
                .having(
                  (SyriusException error) => error.toString(),
                  'toString',
                  isNot(contains(malformedPreimage)),
                ),
          ),
        );

        verify(() => htlcApi.getById(counterHtlcId)).called(1);
        verifyNever(() => htlcApi.unlock(counterHtlcId, any()));
      },
    );
  });
}
