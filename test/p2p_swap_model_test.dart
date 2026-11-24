import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

void main() {
  group('P2pSwap', () {
    test('copyWith creates an updated value without mutating the original', () {
      final HtlcSwap swap = _buildSwap();

      final HtlcSwap updatedSwap = swap.copyWith(
        state: P2pSwapState.active,
        counterHtlcId: 'counter-htlc-id',
      );

      expect(swap.state, P2pSwapState.pending);
      expect(swap.counterHtlcId, isNull);
      expect(updatedSwap.state, P2pSwapState.active);
      expect(updatedSwap.counterHtlcId, 'counter-htlc-id');
      expect(
        updatedSwap,
        swap.copyWith(
          state: P2pSwapState.active,
          counterHtlcId: 'counter-htlc-id',
        ),
      );
    });

    test('round-trips an HTLC swap through polymorphic JSON', () {
      final HtlcSwap swap = _buildSwap();

      final Map<String, dynamic> json = swap.toJson();
      final P2pSwap decodedSwap = P2pSwap.fromJson(json);

      expect(json['mode'], 'htlc');
      expect(json['fromAmount'], '100');
      expect(json['toAmount'], '200');
      expect(
        json['fromToken']['tokenStandard'],
        kZnnCoin.tokenStandard.toString(),
      );
      expect(
        json['toToken']['tokenStandard'],
        kQsrCoin.tokenStandard.toString(),
      );
      expect(decodedSwap, isA<HtlcSwap>());
      expect(decodedSwap, swap);
    });

    test('decodes legacy flattened token metadata', () {
      final Map<String, dynamic> json = _buildSwap().toJson()
        ..remove('fromToken')
        ..remove('toToken')
        ..addAll(<String, dynamic>{
          'fromTokenStandard': kZnnCoin.tokenStandard.toString(),
          'fromSymbol': 'ZNN',
          'fromDecimals': 8,
          'toTokenStandard': kQsrCoin.tokenStandard.toString(),
          'toSymbol': 'QSR',
          'toDecimals': 8,
        });

      final HtlcSwap decodedSwap = P2pSwap.fromJson(json) as HtlcSwap;

      expect(
        decodedSwap.fromToken.tokenStandard.toString(),
        kZnnCoin.tokenStandard.toString(),
      );
      expect(decodedSwap.fromToken.symbol, 'ZNN');
      expect(decodedSwap.fromToken.decimals, 8);
      expect(
        decodedSwap.toToken?.tokenStandard.toString(),
        kQsrCoin.tokenStandard.toString(),
      );
      expect(decodedSwap.toToken?.symbol, 'QSR');
      expect(decodedSwap.toToken?.decimals, 8);
    });

    test('returns the initial HTLC as the outgoing funded HTLC', () {
      final HtlcSwap swap = _buildSwap();

      expect(
        swap.fundedHtlc,
        (id: 'initial-htlc-id', expirationTime: 1000),
      );
    });

    test('returns the counter HTLC as the incoming funded HTLC', () {
      final HtlcSwap swap = _buildSwap(
        direction: P2pSwapDirection.incoming,
        counterHtlcId: 'counter-htlc-id',
        counterHtlcExpirationTime: 2000,
      );

      expect(
        swap.fundedHtlc,
        (id: 'counter-htlc-id', expirationTime: 2000),
      );
    });

    test('has no incoming funded HTLC before the counter HTLC exists', () {
      final HtlcSwap swap = _buildSwap(
        direction: P2pSwapDirection.incoming,
      );

      expect(swap.fundedHtlc, isNull);
    });
  });
}

HtlcSwap _buildSwap({
  P2pSwapDirection direction = P2pSwapDirection.outgoing,
  String? counterHtlcId,
  int? counterHtlcExpirationTime,
}) => HtlcSwap(
  hashLock: 'hash-lock',
  initialHtlcId: 'initial-htlc-id',
  initialHtlcExpirationTime: 1000,
  hashType: 1,
  id: 'swap-id',
  chainId: 1,
  type: P2pSwapType.native,
  direction: direction,
  selfAddress: 'self-address',
  counterpartyAddress: 'counterparty-address',
  fromAmount: BigInt.from(100),
  fromToken: kZnnCoin,
  fromChain: P2pSwapChain.nom,
  toChain: P2pSwapChain.nom,
  startTime: 100,
  state: P2pSwapState.pending,
  toAmount: BigInt.from(200),
  toToken: kQsrCoin,
  counterHtlcId: counterHtlcId,
  counterHtlcExpirationTime: counterHtlcExpirationTime,
);
