import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_addresses/repository/settings_addresses_repository.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

part 'settings_addresses_event.dart';
part 'settings_addresses_state.dart';

/// Manages default address selection, address generation, and address labels.
class SettingsAddressesBloc
    extends Bloc<SettingsAddressesEvent, SettingsAddressesState> {
  /// Creates a [SettingsAddressesBloc].
  factory SettingsAddressesBloc({SettingsAddressesRepository? repository}) {
    final SettingsAddressesRepository resolvedRepository =
        repository ?? HiveSettingsAddressesRepository();
    return SettingsAddressesBloc._(repository: resolvedRepository);
  }

  SettingsAddressesBloc._({required SettingsAddressesRepository repository})
    : _repository = repository,
      super(
        SettingsAddressesState(
          addresses: repository.getAddresses(),
          selectedAddress: repository.getSelectedAddress(),
          addressLabels: repository.getAddressLabels(),
        ),
      ) {
    on<SettingsAddressesDefaultChanged>(_onDefaultChanged);
    on<SettingsAddressesGenerateRequested>(_onGenerateRequested);
    on<SettingsAddressesCountChanged>(_onCountChanged);
    on<SettingsAddressesLabelUpdated>(_onLabelUpdated);
  }

  final SettingsAddressesRepository _repository;

  FutureOr<void> _onDefaultChanged(
    SettingsAddressesDefaultChanged event,
    Emitter<SettingsAddressesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SettingsAddressesStatus.loading,
        numberOfAddressesToAdd: 1,
        clearError: true,
      ),
    );
    try {
      await _repository.saveDefaultAddress(event.address);
      emit(
        state.copyWith(
          status: SettingsAddressesStatus.ready,
          selectedAddress: event.address,
          addresses: _repository.getAddresses(),
          addressLabels: _repository.getAddressLabels(),
          defaultAddressChangeNonce: state.defaultAddressChangeNonce + 1,
          clearError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(status: SettingsAddressesStatus.failure, error: error),
      );
    }
  }

  FutureOr<void> _onGenerateRequested(
    SettingsAddressesGenerateRequested event,
    Emitter<SettingsAddressesState> emit,
  ) async {
    emit(
      state.copyWith(status: SettingsAddressesStatus.loading, clearError: true),
    );
    try {
      await _repository.generateNewAddresses(event.count);
      emit(
        state.copyWith(
          status: SettingsAddressesStatus.ready,
          addresses: _repository.getAddresses(),
          addressLabels: _repository.getAddressLabels(),
          scrollToEndNonce: state.scrollToEndNonce + 1,
          clearError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(status: SettingsAddressesStatus.failure, error: error),
      );
    }
  }

  void _onCountChanged(
    SettingsAddressesCountChanged event,
    Emitter<SettingsAddressesState> emit,
  ) {
    emit(state.copyWith(numberOfAddressesToAdd: event.count));
  }

  FutureOr<void> _onLabelUpdated(
    SettingsAddressesLabelUpdated event,
    Emitter<SettingsAddressesState> emit,
  ) async {
    final String label = event.label;
    final Map<String, String> labels = _repository.getAddressLabels();

    if (label.isEmpty) {
      emit(
        state.copyWith(
          labelUpdateNonce: state.labelUpdateNonce + 1,
          labelError: SettingsAddressLabelError.empty,
          failedLabel: label,
        ),
      );
      return;
    }

    if (label.length > kAddressLabelMaxLength) {
      emit(
        state.copyWith(
          labelUpdateNonce: state.labelUpdateNonce + 1,
          labelError: SettingsAddressLabelError.tooLong,
          failedLabel: label,
        ),
      );
      return;
    }

    if (labels.values.contains(label)) {
      emit(
        state.copyWith(
          labelUpdateNonce: state.labelUpdateNonce + 1,
          labelError: SettingsAddressLabelError.alreadyExists,
          failedLabel: label,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        updatingLabelAddress: event.address,
        clearLabelError: true,
      ),
    );

    try {
      await _repository.updateAddressLabel(
        address: event.address,
        label: label,
      );
      emit(
        state.copyWith(
          addressLabels: _repository.getAddressLabels(),
          clearUpdatingLabelAddress: true,
          labelUpdateNonce: state.labelUpdateNonce + 1,
          clearLabelError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          clearUpdatingLabelAddress: true,
          labelUpdateNonce: state.labelUpdateNonce + 1,
          labelError: SettingsAddressLabelError.unexpected,
          failedLabel: label,
          labelErrorCause: error,
        ),
      );
    }
  }
}
