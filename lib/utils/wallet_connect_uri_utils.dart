String? extractWalletConnectUri(String rawLink, {bool isWindows = false}) {
  String normalized = rawLink.trim();

  if (normalized.isEmpty) {
    return null;
  }

  if (isWindows) {
    normalized = normalized.replaceAll('/?', '?');
  }

  final lower = normalized.toLowerCase();

  if (lower.startsWith('wc:')) {
    return normalized;
  }

  if (lower.startsWith('wc%3a')) {
    final decoded = _decodeUriValue(normalized);
    if (decoded.toLowerCase().startsWith('wc:')) {
      return decoded;
    }
  }

  final parsed = Uri.tryParse(normalized);
  final uriParam = parsed?.queryParameters['uri'];
  if (uriParam != null && uriParam.isNotEmpty) {
    final decoded = _decodeUriValue(uriParam);
    if (decoded.toLowerCase().startsWith('wc:')) {
      return decoded;
    }
  }

  final regex = RegExp(r'uri=([^&]+)', caseSensitive: false);
  final match = regex.firstMatch(normalized);
  if (match != null) {
    final encoded = match.group(1);
    if (encoded != null && encoded.isNotEmpty) {
      final decoded = _decodeUriValue(encoded);
      if (decoded.toLowerCase().startsWith('wc:')) {
        return decoded;
      }
    }
  }

  return null;
}

String _decodeUriValue(String value) {
  var decoded = value;
  for (var i = 0; i < 2; i++) {
    final next = Uri.decodeComponent(decoded);
    if (next == decoded) {
      break;
    }
    decoded = next;
  }
  return decoded;
}
