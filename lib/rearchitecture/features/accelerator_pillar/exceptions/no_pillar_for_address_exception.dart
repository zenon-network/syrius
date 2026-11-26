import 'package:flutter/foundation.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

/// Exception thrown when an address has no associated Pillar owner or producer
/// role required to vote on Accelerator proposals.
@immutable
class NoPillarForAddressException extends SyriusException {
  /// Creates a [NoPillarForAddressException].
  NoPillarForAddressException([super.message = _defaultMessage]);

  static const String _defaultMessage =
      'This address owns or produces no pillar';

  @override
  String localizedMessage(AppLocalizations l10n) =>
      message == _defaultMessage ? l10n.addressOwnsOrProducesNoPillar : message;

  @override
  bool operator ==(Object other) {
    return other is NoPillarForAddressException &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
