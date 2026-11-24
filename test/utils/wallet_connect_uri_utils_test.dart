import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_uri_utils.dart';

void main() {
  group('extractWalletConnectUri', () {
    const String wcDirect =
        'wc:1234abcd@2?relay-protocol=irn&symKey=abcdef0123456789';

    test('returns direct wc uri unchanged', () {
      final String? result = extractWalletConnectUri(wcDirect);
      expect(result, wcDirect);
    });

    test('extracts uri query parameter (encoded)', () {
      final String encoded = Uri.encodeComponent(wcDirect);
      final String input = 'syrius://wc?uri=$encoded';

      final String? result = extractWalletConnectUri(input);
      expect(result, wcDirect);
    });

    test('extracts uri query parameter with windows /? shape', () {
      final String encoded = Uri.encodeComponent(wcDirect);
      final String input = 'syrius://wc/?uri=$encoded';

      final String? result = extractWalletConnectUri(input, isWindows: true);
      expect(result, wcDirect);
    });

    test('handles fully encoded wc uri payload', () {
      final String input = Uri.encodeComponent(wcDirect);

      final String? result = extractWalletConnectUri(input);
      expect(result, wcDirect);
    });

    test('returns null for non-walletconnect link', () {
      const String input = 'syrius://transfer?address=z1xyz&amount=1.0&zts=znn';

      final String? result = extractWalletConnectUri(input);
      expect(result, isNull);
    });

    test('returns null for generic parseable uri', () {
      const String input = 'https://example.com/not-walletconnect';

      final String? result = extractWalletConnectUri(input);
      expect(result, isNull);
    });

    test('returns null for wc uri without required parameters', () {
      const String input = 'wc:1234abcd@2';

      final String? result = extractWalletConnectUri(input);
      expect(result, isNull);
    });

    test('returns null for unsupported WalletConnect version', () {
      const String input = 'wc:1234abcd@1?relay-protocol=irn&symKey=abcdef';

      final String? result = extractWalletConnectUri(input);
      expect(result, isNull);
    });

    test('checks whether a raw value contains a valid wc uri', () {
      final String encoded = Uri.encodeComponent(wcDirect);

      expect(isWalletConnectUri('syrius://wc?uri=$encoded'), isTrue);
      expect(isWalletConnectUri('https://example.com'), isFalse);
    });

    test('returns null for empty link', () {
      final String? result = extractWalletConnectUri('   ');
      expect(result, isNull);
    });
  });
}
