part of 'hardware_wallet_device_bloc.dart';

/// Base class for hardware wallet discovery and selection events.
sealed class HardwareWalletDeviceEvent extends Equatable {
  /// Creates a [HardwareWalletDeviceEvent].
  const HardwareWalletDeviceEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initializes the hardware wallet screen by clearing any stale cached
/// addresses box.
final class HardwareWalletDeviceInitialized extends HardwareWalletDeviceEvent {
  /// Creates a [HardwareWalletDeviceInitialized] event.
  const HardwareWalletDeviceInitialized();
}

/// Scans connected hardware wallet devices across configured managers.
final class HardwareWalletDevicesScanRequested
    extends HardwareWalletDeviceEvent {
  /// Creates a [HardwareWalletDevicesScanRequested] event.
  const HardwareWalletDevicesScanRequested();
}

/// Connects to [device] and resolves its base address for confirmation.
final class HardwareWalletDeviceSelected extends HardwareWalletDeviceEvent {
  /// Creates a [HardwareWalletDeviceSelected] event.
  const HardwareWalletDeviceSelected({
    required this.device,
    required this.confirmAddressTitle,
    required this.confirmAddressDetails,
    required this.notConnectedMessage,
    required this.errorMessageBuilder,
  });

  /// Selected hardware wallet device definition.
  final WalletDefinition device;

  /// Localized notification title prompting address confirmation on device.
  final String confirmAddressTitle;

  /// Localized notification details for account index 0 confirmation.
  final String confirmAddressDetails;

  /// Localized error message when no manager can connect to the device.
  final String notConnectedMessage;

  /// Formats unexpected non-Ledger error text.
  final String Function(String details) errorMessageBuilder;

  @override
  List<Object?> get props => <Object?>[
    device,
    confirmAddressTitle,
    confirmAddressDetails,
    notConnectedMessage,
  ];
}
