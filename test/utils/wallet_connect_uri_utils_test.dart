import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_uri_utils.dart';

void main() {
  group('extractWalletConnectUri', () {
    const wcDirect = 'wc:1234abcd@2?relay-protocol=irn&symKey=abcdef0123456789';

    test('returns direct wc uri unchanged', () {
      final result = extractWalletConnectUri(wcDirect);
      expect(result, wcDirect);
    });

    test('extracts uri query parameter (encoded)', () {
      final encoded = Uri.encodeComponent(wcDirect);
      final input = 'syrius://wc?uri=$encoded';

      final result = extractWalletConnectUri(input);
      expect(result, wcDirect);
    });

    test('extracts uri query parameter with windows /? shape', () {
      final encoded = Uri.encodeComponent(wcDirect);
      final input = 'syrius://wc/?uri=$encoded';

      final result = extractWalletConnectUri(input, isWindows: true);
      expect(result, wcDirect);
    });

    test('handles fully encoded wc uri payload', () {
      final input = Uri.encodeComponent(wcDirect);

      final result = extractWalletConnectUri(input);
      expect(result, wcDirect);
    });

    test('returns null for non-walletconnect link', () {
      const input = 'syrius://transfer?address=z1xyz&amount=1.0&zts=znn';

      final result = extractWalletConnectUri(input);
      expect(result, isNull);
    });

    test('returns null for empty link', () {
      final result = extractWalletConnectUri('   ');
      expect(result, isNull);
    });
  });
}
