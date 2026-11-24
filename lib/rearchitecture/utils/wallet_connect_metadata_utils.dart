import 'package:intl/intl.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

/// Verification status level derived from WalletConnect's [VerifyContext].
enum WalletConnectVerifySeverity {
  /// Origin matched the dApp's verified domain registry entry.
  verified,

  /// Origin could not be verified or no verify context was provided.
  unverified,

  /// Claimed metadata URL did not match the attested origin.
  invalid,

  /// Origin was flagged as a known scam by WalletConnect's Verify API.
  scam,
}

/// Display summary describing a peer's WalletConnect verification status.
class WalletConnectVerifySummary {
  /// Creates a [WalletConnectVerifySummary].
  const WalletConnectVerifySummary({
    required this.severity,
    required this.title,
    required this.detail,
  });

  /// Classification of the peer's verification state.
  final WalletConnectVerifySeverity severity;

  /// Short human-readable heading for confirmation dialogs.
  final String title;

  /// Additional context explaining the verification result.
  final String detail;
}

/// Returns `true` when WalletConnect Verify flags [verifyContext] as a scam.
bool isWalletConnectVerifyScam(VerifyContext? verifyContext) {
  if (verifyContext == null) {
    return false;
  }
  return (verifyContext.isScam ?? false) ||
      verifyContext.validation == Validation.SCAM;
}

/// Converts an optional [VerifyContext] into a display-ready status summary.
WalletConnectVerifySummary describeWalletConnectVerifyContext(
  VerifyContext? verifyContext,
) {
  if (isWalletConnectVerifyScam(verifyContext)) {
    final String origin = verifyContext?.origin.trim() ?? '';
    return WalletConnectVerifySummary(
      severity: WalletConnectVerifySeverity.scam,
      title: 'Security warning: flagged as scam',
      detail: origin.isNotEmpty
          ? 'WalletConnect Verify flagged $origin as a known scam.'
          : 'WalletConnect Verify flagged this peer as a known scam.',
    );
  }

  if (verifyContext == null || verifyContext.validation == Validation.UNKNOWN) {
    return const WalletConnectVerifySummary(
      severity: WalletConnectVerifySeverity.unverified,
      title: 'Unverified domain',
      detail:
          'This dApp origin could not be verified. Confirm the URL before '
          'approving.',
    );
  }

  final String origin = verifyContext.origin.trim();
  if (verifyContext.validation == Validation.INVALID) {
    return WalletConnectVerifySummary(
      severity: WalletConnectVerifySeverity.invalid,
      title: 'Warning: domain mismatch',
      detail: origin.isNotEmpty
          ? 'Claimed dApp metadata does not match attested origin $origin. '
                'This may be a phishing attempt.'
          : 'Claimed dApp metadata does not match the attested origin. '
                'This may be a phishing attempt.',
    );
  }

  return WalletConnectVerifySummary(
    severity: WalletConnectVerifySeverity.verified,
    title: 'Verified domain',
    detail: origin.isNotEmpty
        ? 'Verified origin: $origin'
        : 'Origin verified by WalletConnect.',
  );
}

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
