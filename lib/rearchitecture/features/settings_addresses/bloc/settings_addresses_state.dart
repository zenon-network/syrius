part of 'settings_addresses_bloc.dart';

/// Operation status for [SettingsAddressesBloc].
enum SettingsAddressesStatus {
  /// Idle and ready for interaction.
  ready,

  /// Changing default address or generating new addresses.
  loading,

  /// Fatal error while loading or mutating addresses.
  failure,
}

/// Validation failure reasons for updating an address label.
enum SettingsAddressLabelError {
  /// Label text was empty.
  empty,

  /// Label exceeded [kAddressLabelMaxLength].
  tooLong,

  /// Another address already uses this label.
  alreadyExists,

  /// Unexpected persistence error.
  unexpected,
}

/// State emitted by [SettingsAddressesBloc].
class SettingsAddressesState extends Equatable {
  /// Creates a [SettingsAddressesState].
  const SettingsAddressesState({
    required this.addresses,
    required this.selectedAddress,
    required this.addressLabels,
    this.status = SettingsAddressesStatus.ready,
    this.numberOfAddressesToAdd = 1,
    this.scrollToEndNonce = 0,
    this.defaultAddressChangeNonce = 0,
    this.updatingLabelAddress,
    this.labelUpdateNonce = 0,
    this.labelError,
    this.failedLabel,
    this.labelErrorCause,
    this.error,
  });

  /// Wallet addresses currently available.
  final List<String> addresses;

  /// Currently selected default wallet address.
  final String? selectedAddress;

  /// Map of address string to display label.
  final Map<String, String> addressLabels;

  /// Current card-level loading/ready/failure status.
  final SettingsAddressesStatus status;

  /// Number of addresses chosen to add.
  final int numberOfAddressesToAdd;

  /// Incremented whenever the address list should scroll to the bottom.
  final int scrollToEndNonce;

  /// Incremented whenever the default address was successfully changed.
  final int defaultAddressChangeNonce;

  /// Address whose label is currently being persisted, if any.
  final String? updatingLabelAddress;

  /// Incremented on every label update outcome.
  final int labelUpdateNonce;

  /// Validation or persistence error from the latest label update, if any.
  final SettingsAddressLabelError? labelError;

  /// The label value that triggered [labelError], if any.
  final String? failedLabel;

  /// Underlying error object when [labelError] is unexpected.
  final Object? labelErrorCause;

  /// Fatal error object when [status] is [SettingsAddressesStatus.failure].
  final Object? error;

  /// Returns a copy of this state with updated fields.
  SettingsAddressesState copyWith({
    List<String>? addresses,
    String? selectedAddress,
    Map<String, String>? addressLabels,
    SettingsAddressesStatus? status,
    int? numberOfAddressesToAdd,
    int? scrollToEndNonce,
    int? defaultAddressChangeNonce,
    String? updatingLabelAddress,
    bool clearUpdatingLabelAddress = false,
    int? labelUpdateNonce,
    SettingsAddressLabelError? labelError,
    bool clearLabelError = false,
    String? failedLabel,
    Object? labelErrorCause,
    Object? error,
    bool clearError = false,
  }) {
    return SettingsAddressesState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      addressLabels: addressLabels ?? this.addressLabels,
      status: status ?? this.status,
      numberOfAddressesToAdd:
          numberOfAddressesToAdd ?? this.numberOfAddressesToAdd,
      scrollToEndNonce: scrollToEndNonce ?? this.scrollToEndNonce,
      defaultAddressChangeNonce:
          defaultAddressChangeNonce ?? this.defaultAddressChangeNonce,
      updatingLabelAddress: clearUpdatingLabelAddress
          ? null
          : (updatingLabelAddress ?? this.updatingLabelAddress),
      labelUpdateNonce: labelUpdateNonce ?? this.labelUpdateNonce,
      labelError: clearLabelError ? null : (labelError ?? this.labelError),
      failedLabel: clearLabelError ? null : (failedLabel ?? this.failedLabel),
      labelErrorCause: clearLabelError
          ? null
          : (labelErrorCause ?? this.labelErrorCause),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    addresses,
    selectedAddress,
    addressLabels,
    status,
    numberOfAddressesToAdd,
    scrollToEndNonce,
    defaultAddressChangeNonce,
    updatingLabelAddress,
    labelUpdateNonce,
    labelError,
    failedLabel,
    labelErrorCause,
    error,
  ];
}
