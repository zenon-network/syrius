part of 'hardware_wallet_device_bloc.dart';

/// State representing discovered hardware wallet devices and connection status.
final class HardwareWalletDeviceState extends Equatable {
  /// Creates a [HardwareWalletDeviceState].
  const HardwareWalletDeviceState({
    this.devices = const <WalletDefinition>[],
    this.selectedDevice,
    this.deviceMessages = const <String, String?>{},
    this.isScanning = false,
    this.isConnecting = false,
  });

  /// Hardware wallet devices found in the latest scan.
  final List<WalletDefinition> devices;

  /// Device that has been connected and had its base address confirmed.
  final WalletDefinition? selectedDevice;

  /// Per-device status text (resolved address or connection error), keyed by
  /// `walletId`.
  final Map<String, String?> deviceMessages;

  /// Whether a device scan is currently in progress.
  final bool isScanning;

  /// Whether a device connection/address confirmation is currently in progress.
  final bool isConnecting;

  @override
  List<Object?> get props => <Object?>[
    devices,
    selectedDevice,
    deviceMessages,
    isScanning,
    isConnecting,
  ];
}
