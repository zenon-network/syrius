import 'package:intl/intl.dart';

/// Returns a trimmed display label for [rawValue], falling back to [fallback]
/// when empty or the literal string `'null'`.
String walletConnectDisplayValue(String? rawValue, String fallback) {
  final String trimmed = rawValue?.trim() ?? '';
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
    return fallback;
  }
  return trimmed;
}

/// Returns [rawUrl] trimmed only when it parses as a well-formed `http` or
/// `https` URL with a non-empty authority/host; otherwise returns `null`.
String? sanitizeWalletConnectHttpUrl(String? rawUrl) {
  final String trimmed = rawUrl?.trim() ?? '';
  final Uri? uri = Uri.tryParse(trimmed);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      !uri.hasAuthority ||
      uri.host.isEmpty) {
    return null;
  }
  return trimmed;
}

/// Formats a WalletConnect Unix expiry timestamp (in seconds) for table rows.
String formatWalletConnectExpiry(int expirySeconds) {
  final DateTime expiryDateTime = DateTime.fromMillisecondsSinceEpoch(
    expirySeconds * 1000,
  );
  return DateFormat('MMM dd, y HH:mm:ss').format(expiryDateTime);
}
