import 'package:flutter/foundation.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

/// Exception thrown when a donation request specifies zero ZNN and zero QSR.
@immutable
class InvalidDonationAmountException extends SyriusException {
  /// Creates an [InvalidDonationAmountException].
  InvalidDonationAmountException([super.message = _defaultMessage]);

  static const String _defaultMessage =
      'Donation amount must be greater than zero';

  @override
  String localizedMessage(AppLocalizations l10n) =>
      message == _defaultMessage ? l10n.donationAmountMustBePositive : message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvalidDonationAmountException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
