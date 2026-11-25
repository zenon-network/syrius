part of 'settings_addresses_bloc.dart';

/// Base class for [SettingsAddressesBloc] events.
sealed class SettingsAddressesEvent extends Equatable {
  /// Creates a [SettingsAddressesEvent].
  const SettingsAddressesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Changes the default selected wallet address to [address].
final class SettingsAddressesDefaultChanged extends SettingsAddressesEvent {
  /// Creates a [SettingsAddressesDefaultChanged] event.
  const SettingsAddressesDefaultChanged({required this.address});

  /// The address selected by the user.
  final String address;

  @override
  List<Object?> get props => <Object?>[address];
}

/// Generates [count] new addresses in the wallet.
final class SettingsAddressesGenerateRequested extends SettingsAddressesEvent {
  /// Creates a [SettingsAddressesGenerateRequested] event.
  const SettingsAddressesGenerateRequested({required this.count});

  /// Number of addresses to generate.
  final int count;

  @override
  List<Object?> get props => <Object?>[count];
}

/// Updates the number of addresses selected in the add-address selector.
final class SettingsAddressesCountChanged extends SettingsAddressesEvent {
  /// Creates a [SettingsAddressesCountChanged] event.
  const SettingsAddressesCountChanged({required this.count});

  /// Selected count to generate.
  final int count;

  @override
  List<Object?> get props => <Object?>[count];
}

/// Updates the custom label for [address].
final class SettingsAddressesLabelUpdated extends SettingsAddressesEvent {
  /// Creates a [SettingsAddressesLabelUpdated] event.
  const SettingsAddressesLabelUpdated({
    required this.address,
    required this.label,
  });

  /// Target wallet address.
  final String address;

  /// Proposed new label.
  final String label;

  @override
  List<Object?> get props => <Object?>[address, label];
}
