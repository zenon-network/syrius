import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/syrius_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/l10n/app_localizations_resolver.dart';

/// Identifies a localizable domain error raised outside the widget tree.
enum SyriusErrorCode {
  /// The supplied password failed wallet decryption.
  incorrectPassword,

  /// The wallet must be unlocked before performing the requested operation.
  walletNotUnlocked,

  /// No wallet address is currently selected.
  noWalletAddressSelected,

  /// An address is missing from the wallet's generated address list.
  addressNotInWalletList,

  /// Token metadata could not be retrieved for an HTLC deposit.
  unableToRetrieveTokenInformation,

  /// The HTLC deposit's hash-locked recipient is not owned by this wallet.
  depositNotIntendedForYou,

  /// The user attempted to join a swap that they themselves started.
  cannotJoinOwnSwap,

  /// The HTLC deposit ID is already tracked in another local swap.
  depositAlreadyUsedInSwap,

  /// The HTLC deposit's hashlock is already tracked in another local swap.
  depositHashlockAlreadyUsedInSwap,

  /// The HTLC deposit has already expired.
  depositExpired,

  /// The HTLC deposit expires too soon to safely join the swap.
  depositExpiresTooSoonForSafeSwap,

  /// The creation momentum timestamp of the HTLC deposit could not be read.
  unableToVerifyDepositCreationTime,

  /// The HTLC deposit's duration exceeds the allowed maximum.
  depositDurationTooLong,

  /// Another on-chain HTLC already uses the same hashlock.
  hashlockNotUnique,

  /// The requested swap could not be found in local storage.
  swapDoesNotExist,

  /// The swap record or on-chain HTLC does not match the expected invariants.
  invalidSwap,

  /// The swap's unlock address is missing from the default address list.
  swapAddressNotInDefaultAddresses,

  /// The swap expires too soon to safely complete on-chain.
  swapExpiresTooSoonForSafeSwap,

  /// The swap preimage could not be decoded as valid hexadecimal bytes.
  invalidSwapSecret,

  /// The swap preimage exceeds the HTLC's maximum key size.
  swapSecretExceedsMaxSize,

  /// The HTLC deposit is still time-locked until a future timestamp.
  depositLockedUntil,

  /// The HTLC deposit's time-locked owner is not derived from this wallet.
  depositDoesNotBelongToYou,

  /// A hardware wallet cannot automatically scan for a missing deposit address.
  depositAddressNotInWalletAddresses,

  /// Generating additional addresses did not populate the expected deposit
  /// address in the wallet address list.
  unableToAddDepositAddressToWallet,
}

/// A [SyriusException] backed by a typed [SyriusErrorCode] so BLoCs and
/// services can emit localizable domain errors without a `BuildContext`.
@immutable
class LocalizedSyriusException extends SyriusException {
  /// Creates a [LocalizedSyriusException] for [code] with optional named
  /// [arguments].
  LocalizedSyriusException(
    this.code, {
    Map<String, Object> arguments = const <String, Object>{},
  }) : arguments = Map<String, Object>.unmodifiable(arguments),
       super(_resolveMessage(code, arguments, resolveAppLocalizations()));

  /// Creates an error indicating [address] is missing from the wallet address
  /// list.
  LocalizedSyriusException.addressNotInWalletList({required String address})
    : this(
        SyriusErrorCode.addressNotInWalletList,
        arguments: <String, Object>{'address': address},
      );

  /// Creates an error indicating an initial HTLC deposit exceeds [maxHours].
  LocalizedSyriusException.depositDurationTooLong({required int maxHours})
    : this(
        SyriusErrorCode.depositDurationTooLong,
        arguments: <String, Object>{'maxHours': maxHours},
      );

  /// Creates an error indicating a deposit remains locked until
  /// [expirationDate].
  LocalizedSyriusException.depositLockedUntil({required String expirationDate})
    : this(
        SyriusErrorCode.depositLockedUntil,
        arguments: <String, Object>{'expirationDate': expirationDate},
      );

  /// Deserializes a [LocalizedSyriusException] from [json], falling back to a
  /// plain [SyriusException] if [json] contains an unrecognized error code.
  static SyriusException fromJsonOrFallback(Map<String, dynamic> json) {
    final String? codeName = json['code'] as String?;
    final SyriusErrorCode? code = SyriusErrorCode.values.firstWhereOrNull(
      (SyriusErrorCode value) => value.name == codeName,
    );
    if (code == null) {
      return SyriusException((json['message'] as String?) ?? '');
    }

    final Map<String, Object> parsedArguments = <String, Object>{};
    final Object? rawArguments = json['arguments'];
    if (rawArguments is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawArguments.entries) {
        final Object? value = entry.value;
        if (value != null) {
          parsedArguments[entry.key] = value;
        }
      }
    }

    return LocalizedSyriusException(code, arguments: parsedArguments);
  }

  /// Machine-readable error code mapped at the presentation boundary.
  final SyriusErrorCode code;

  /// Optional structured interpolation arguments for [code].
  final Map<String, Object> arguments;

  @override
  String localizedMessage(AppLocalizations l10n) =>
      _resolveMessage(code, arguments, l10n);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'runtimeType': 'LocalizedSyriusException',
    'code': code.name,
    'arguments': arguments,
    'message': message,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LocalizedSyriusException &&
            other.runtimeType == runtimeType &&
            other.code == code &&
            const MapEquality<String, Object>().equals(
              other.arguments,
              arguments,
            );
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    const MapEquality<String, Object>().hash(arguments),
  );

  static String _resolveMessage(
    SyriusErrorCode code,
    Map<String, Object> arguments,
    AppLocalizations l10n,
  ) {
    return switch (code) {
      SyriusErrorCode.incorrectPassword => l10n.incorrectPassword,
      SyriusErrorCode.walletNotUnlocked => l10n.walletNotUnlocked,
      SyriusErrorCode.noWalletAddressSelected => l10n.noWalletAddressSelected,
      SyriusErrorCode.addressNotInWalletList => l10n.addressNotInWalletList(
        _stringArg(arguments, 'address'),
      ),
      SyriusErrorCode.unableToRetrieveTokenInformation =>
        l10n.unableToRetrieveTokenInformation,
      SyriusErrorCode.depositNotIntendedForYou => l10n.depositNotIntendedForYou,
      SyriusErrorCode.cannotJoinOwnSwap => l10n.cannotJoinOwnSwap,
      SyriusErrorCode.depositAlreadyUsedInSwap => l10n.depositAlreadyUsedInSwap,
      SyriusErrorCode.depositHashlockAlreadyUsedInSwap =>
        l10n.depositHashlockAlreadyUsedInSwap,
      SyriusErrorCode.depositExpired => l10n.depositExpired,
      SyriusErrorCode.depositExpiresTooSoonForSafeSwap =>
        l10n.depositExpiresTooSoonForSafeSwap,
      SyriusErrorCode.unableToVerifyDepositCreationTime =>
        l10n.unableToVerifyDepositCreationTime,
      SyriusErrorCode.depositDurationTooLong => l10n.depositDurationTooLong(
        _intArg(arguments, 'maxHours'),
      ),
      SyriusErrorCode.hashlockNotUnique => l10n.hashlockNotUnique,
      SyriusErrorCode.swapDoesNotExist => l10n.swapDoesNotExist,
      SyriusErrorCode.invalidSwap => l10n.invalidSwap,
      SyriusErrorCode.swapAddressNotInDefaultAddresses =>
        l10n.swapAddressNotInDefaultAddresses,
      SyriusErrorCode.swapExpiresTooSoonForSafeSwap =>
        l10n.swapExpiresTooSoonForSafeSwap,
      SyriusErrorCode.invalidSwapSecret => l10n.invalidSwapSecret,
      SyriusErrorCode.swapSecretExceedsMaxSize => l10n.swapSecretExceedsMaxSize,
      SyriusErrorCode.depositLockedUntil => l10n.depositLockedUntil(
        _stringArg(arguments, 'expirationDate'),
      ),
      SyriusErrorCode.depositDoesNotBelongToYou =>
        l10n.depositDoesNotBelongToYou,
      SyriusErrorCode.depositAddressNotInWalletAddresses =>
        l10n.depositAddressNotInWalletAddresses,
      SyriusErrorCode.unableToAddDepositAddressToWallet =>
        l10n.unableToAddDepositAddressToWallet,
    };
  }

  static String _stringArg(Map<String, Object> arguments, String key) {
    final Object? value = arguments[key];
    return value?.toString() ?? '';
  }

  static int _intArg(Map<String, Object> arguments, String key) {
    final Object? value = arguments[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
