/// Visual strength tiers for a wallet password.
enum PasswordStrengthTier {
  /// Password field is empty.
  empty,

  /// Non-empty password shorter than 8 characters or failing validation.
  weak,

  /// Valid password with length in `[8, 16)`.
  medium,

  /// Valid password with length at least `16`.
  strong,
}

/// Classifies [password] into a [PasswordStrengthTier] using its length and
/// complexity validation result [isValid].
PasswordStrengthTier classifyPasswordStrength(
  String password, {
  required bool isValid,
}) {
  if (password.isEmpty) {
    return PasswordStrengthTier.empty;
  }
  if (!isValid || password.length < 8) {
    return PasswordStrengthTier.weak;
  }
  if (password.length < 16) {
    return PasswordStrengthTier.medium;
  }
  return PasswordStrengthTier.strong;
}
