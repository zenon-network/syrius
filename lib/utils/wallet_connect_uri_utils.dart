/// Extracts and validates a WalletConnect v2 URI (`wc:<topic>@2?...`) from
/// direct links, percent-encoded strings, or wrapper deep links such as
/// `syrius://wc?uri=...`.
String? extractWalletConnectUri(String rawLink, {bool isWindows = false}) {
  String normalized = rawLink.trim();

  if (normalized.isEmpty) {
    return null;
  }

  if (isWindows) {
    normalized = normalized.replaceAll('/?', '?');
  }

  final String lower = normalized.toLowerCase();

  if (lower.startsWith('wc:') && _isValidWalletConnectUri(normalized)) {
    return normalized;
  }

  if (lower.startsWith('wc%3a')) {
    final String decoded = _decodeUriValue(normalized);
    if (_isValidWalletConnectUri(decoded)) {
      return decoded;
    }
  }

  final Uri? parsed = Uri.tryParse(normalized);
  final String? uriParam = parsed?.queryParameters['uri'];
  if (uriParam != null && uriParam.isNotEmpty) {
    final String decoded = _decodeUriValue(uriParam);
    if (_isValidWalletConnectUri(decoded)) {
      return decoded;
    }
  }

  final RegExp regex = RegExp('uri=([^&]+)', caseSensitive: false);
  final RegExpMatch? match = regex.firstMatch(normalized);
  if (match != null) {
    final String? encoded = match.group(1);
    if (encoded != null && encoded.isNotEmpty) {
      final String decoded = _decodeUriValue(encoded);
      if (_isValidWalletConnectUri(decoded)) {
        return decoded;
      }
    }
  }

  return null;
}

/// Returns whether [rawLink] contains a valid WalletConnect v2 URI.
bool isWalletConnectUri(String rawLink, {bool isWindows = false}) {
  return extractWalletConnectUri(rawLink, isWindows: isWindows) != null;
}

bool _isValidWalletConnectUri(String value) {
  final String normalized = value.trim();
  final RegExpMatch? match = RegExp(
    r'^wc:([^@?\s]+)@(\d+)\?(.+)$',
    caseSensitive: false,
  ).firstMatch(normalized);

  if (match == null) {
    return false;
  }

  if (match.group(2) != '2') {
    return false;
  }

  final String? query = match.group(3);
  if (query == null || query.isEmpty) {
    return false;
  }

  try {
    final Map<String, String> queryParameters = Uri.splitQueryString(query);
    return (queryParameters['relay-protocol']?.isNotEmpty ?? false) &&
        (queryParameters['symKey']?.isNotEmpty ?? false);
  } on Object {
    return false;
  }
}

String _decodeUriValue(String value) {
  String decoded = value;
  for (int i = 0; i < 2; i++) {
    final String next = Uri.decodeComponent(decoded);
    if (next == decoded) {
      break;
    }
    decoded = next;
  }
  return decoded;
}
