import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'hardware_wallet_device_event.dart';
part 'hardware_wallet_device_state.dart';

/// BLoC managing hardware wallet device scanning, selection, and address
/// verification during onboarding.
class HardwareWalletDeviceBloc
    extends Bloc<HardwareWalletDeviceEvent, HardwareWalletDeviceState> {
  /// Creates a [HardwareWalletDeviceBloc].
  HardwareWalletDeviceBloc({
    List<WalletManager>? walletManagers,
    Future<void> Function()? clearAddressesBox,
    Future<void> Function(WalletNotification notification)? sendNotification,
  }) : _walletManagers =
           walletManagers ?? <WalletManager>[LedgerWalletManager()],
       _clearAddressesBox = clearAddressesBox ?? _defaultClearAddressesBox,
       _sendNotification = sendNotification ?? _defaultSendNotification,
       super(const HardwareWalletDeviceState()) {
    on<HardwareWalletDeviceEvent>(_onEvent, transformer: sequential());
  }

  final List<WalletManager> _walletManagers;
  final Future<void> Function() _clearAddressesBox;
  final Future<void> Function(WalletNotification notification)
  _sendNotification;

  Future<void> _onEvent(
    HardwareWalletDeviceEvent event,
    Emitter<HardwareWalletDeviceState> emit,
  ) async {
    switch (event) {
      case HardwareWalletDeviceInitialized():
        await _onInitialized();
      case HardwareWalletDevicesScanRequested():
        await _onScanRequested(emit);
      case HardwareWalletDeviceSelected():
        await _onDeviceSelected(event, emit);
    }
  }

  Future<void> _onInitialized() async {
    try {
      await _clearAddressesBox();
    } on Object catch (error, stackTrace) {
      Logger(
        'HardwareWalletDeviceBloc',
      ).log(Level.WARNING, '_onInitialized', error, stackTrace);
    }
  }

  Future<void> _onScanRequested(Emitter<HardwareWalletDeviceState> emit) async {
    emit(
      HardwareWalletDeviceState(
        devices: state.devices,
        selectedDevice: state.selectedDevice,
        deviceMessages: state.deviceMessages,
        isScanning: true,
      ),
    );
    try {
      final List<Future<Iterable<WalletDefinition>>> futures = _walletManagers
          .map<Future<Iterable<WalletDefinition>>>(
            (WalletManager manager) => manager.getWalletDefinitions(),
          )
          .toList();

      final List<Iterable<WalletDefinition>> listOfDefinitions =
          await Future.wait<Iterable<WalletDefinition>>(futures);

      final List<WalletDefinition> combinedList = listOfDefinitions
          .expand<WalletDefinition>(
            (Iterable<WalletDefinition> element) => element,
          )
          .toList();

      final Map<String, String?> clearedMessages = <String, String?>{
        for (final WalletDefinition device in combinedList)
          device.walletId: null,
      };

      emit(
        HardwareWalletDeviceState(
          devices: combinedList,
          deviceMessages: clearedMessages,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        HardwareWalletDeviceState(
          devices: state.devices,
          selectedDevice: state.selectedDevice,
          deviceMessages: state.deviceMessages,
        ),
      );
    }
  }

  Future<void> _onDeviceSelected(
    HardwareWalletDeviceSelected event,
    Emitter<HardwareWalletDeviceState> emit,
  ) async {
    emit(
      HardwareWalletDeviceState(
        devices: state.devices,
        selectedDevice: state.selectedDevice,
        deviceMessages: state.deviceMessages,
        isConnecting: true,
      ),
    );

    Wallet? wallet;
    try {
      for (final WalletManager walletManager in _walletManagers) {
        if (await walletManager.supportsWallet(event.device)) {
          wallet = await walletManager.getWallet(event.device);
          break;
        }
      }
      if (wallet == null) {
        final Map<String, String?> updatedMessages = Map<String, String?>.of(
          state.deviceMessages,
        )..[event.device.walletId] = event.notConnectedMessage;
        emit(
          HardwareWalletDeviceState(
            devices: state.devices,
            deviceMessages: updatedMessages,
          ),
        );
        return;
      }

      final Address walletAddress = await _getWalletAddress(wallet, event);
      final Map<String, String?> updatedMessages = Map<String, String?>.of(
        state.deviceMessages,
      )..[event.device.walletId] = walletAddress.toString();

      emit(
        HardwareWalletDeviceState(
          devices: state.devices,
          selectedDevice: event.device,
          deviceMessages: updatedMessages,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      final String errorText = error is LedgerError
          ? error.toFriendlyString()
          : event.errorMessageBuilder(error.toString());
      final Map<String, String?> updatedMessages = Map<String, String?>.of(
        state.deviceMessages,
      )..[event.device.walletId] = errorText;

      emit(
        HardwareWalletDeviceState(
          devices: state.devices,
          deviceMessages: updatedMessages,
        ),
      );
    } finally {
      if (wallet is LedgerWallet) {
        try {
          await wallet.disconnect();
        } on Object catch (_) {}
      }
    }
  }

  Future<Address> _getWalletAddress(
    Wallet wallet,
    HardwareWalletDeviceSelected event,
  ) async {
    final WalletAccount account = await wallet.getAccount();
    if (account is LedgerWalletAccount) {
      await _sendNotification(
        WalletNotification(
          title: event.confirmAddressTitle,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: event.confirmAddressDetails,
          type: NotificationType.confirm,
        ),
      );
      return await account.getAddress(true);
    }
    return await account.getAddress();
  }

  static Future<void> _defaultClearAddressesBox() async {
    final bool addressesBoxExists = await Hive.boxExists(kAddressesBox);
    if (addressesBoxExists) {
      final Box<dynamic> addressesBox = await Hive.openBox<dynamic>(
        kAddressesBox,
      );
      await addressesBox.clear();
    }
  }

  static Future<void> _defaultSendNotification(
    WalletNotification notification,
  ) async {
    await sl.get<NotificationsBloc>().addNotification(notification);
  }
}
