import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Onboarding screen for discovering and verifying a hardware wallet device.
class HardwareWalletDeviceChoiceScreen extends StatelessWidget {
  /// Creates a [HardwareWalletDeviceChoiceScreen].
  const HardwareWalletDeviceChoiceScreen({
    this._deviceBloc,
    this._showNotificationBanner = true,
    super.key,
  });

  final HardwareWalletDeviceBloc? _deviceBloc;
  final bool _showNotificationBanner;

  @override
  Widget build(BuildContext context) {
    final Widget view = _View(showNotificationBanner: _showNotificationBanner);
    final HardwareWalletDeviceBloc? injectedBloc = _deviceBloc;
    if (injectedBloc != null) {
      return BlocProvider<HardwareWalletDeviceBloc>.value(
        value: injectedBloc,
        child: view,
      );
    }

    return BlocProvider<HardwareWalletDeviceBloc>(
      create: (_) =>
          HardwareWalletDeviceBloc()
            ..add(const HardwareWalletDeviceInitialized()),
      child: view,
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this._showNotificationBanner});

  final bool _showNotificationBanner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HardwareWalletDeviceBloc, HardwareWalletDeviceState>(
        builder: (BuildContext context, HardwareWalletDeviceState state) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const ProgressBar(currentLevel: 1, numLevels: 4),
                    const SizedBox(height: 30),
                    if (_showNotificationBanner) const NotificationWidget(),
                    Text(
                      context.l10n.chooseYourDevice,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    kVerticalSpacing,
                    Text(
                      context.l10n.connectAndUnlockYourDevice,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    kVerticalSpacing,
                    SizedBox(
                      height: 40,
                      child: _buildScanDevicesButton(context, state),
                    ),
                    kVerticalSpacing,
                    SizedBox(
                      width: 420,
                      child: _buildDevicesList(context, state),
                    ),
                  ],
                ),
                _buildActionButtons(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanDevicesButton(
    BuildContext context,
    HardwareWalletDeviceState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: AppColors.znnColor),
      ),
      child: InkWell(
        onTap: state.isScanning
            ? null
            : () => context.read<HardwareWalletDeviceBloc>().add(
                const HardwareWalletDevicesScanRequested(),
              ),
        child: FocusableActionDetector(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150, minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.search,
                    color: Theme.of(context).textTheme.headlineSmall!.color,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.scanDevices,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevicesList(
    BuildContext context,
    HardwareWalletDeviceState state,
  ) {
    return RadioGroup<WalletDefinition?>(
      groupValue: state.selectedDevice,
      onChanged: (WalletDefinition? device) {
        if (device != null) {
          _onDeviceSelected(context, device);
        }
      },
      child: Column(
        children: state.devices
            .map<Widget>(
              (WalletDefinition device) => _buildDeviceTile(
                context,
                device,
                state.deviceMessages[device.walletId],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    WalletDefinition device,
    String? statusMessage,
  ) {
    return Row(
      children: <Widget>[
        Radio<WalletDefinition?>(value: device),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _onDeviceSelected(context, device),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _getWalletName(context, device),
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color!
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                          SizedBox(
                            height: 20,
                            child: statusMessage == null
                                ? Text(context.l10n.selectToConnectDevice)
                                : Text(
                                    statusMessage,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onDeviceSelected(BuildContext context, WalletDefinition device) {
    context.read<HardwareWalletDeviceBloc>().add(
      HardwareWalletDeviceSelected(
        device: device,
        confirmAddressTitle: context.l10n.resolvingAddressConfirmOnDevice,
        confirmAddressDetails: context.l10n.confirmAddressAccountIndex(0),
        notConnectedMessage: context.l10n.deviceNotConnectedTryAgain,
        errorMessageBuilder: context.l10n.errorWithMessage,
      ),
    );
  }

  String _getWalletName(
    BuildContext context,
    WalletDefinition walletDefinition,
  ) {
    if (walletDefinition is LedgerWalletDefinition) {
      return context.l10n.ledgerWithName(walletDefinition.walletName);
    }
    return walletDefinition.walletName;
  }

  Widget _buildActionButtons(
    BuildContext context,
    HardwareWalletDeviceState state,
  ) {
    final WalletDefinition? selectedDevice = state.selectedDevice;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OnboardingButton(
          onPressed: () => Navigator.pop(context),
          text: context.l10n.goBack,
        ),
        kSpacingBetweenActionButtons,
        OnboardingButton(
          onPressed: selectedDevice != null
              ? () {
                  NavigationUtils.push(
                    context,
                    HardwareWalletPasswordScreen(selectedDevice),
                  );
                }
              : null,
          text: context.l10n.continueText,
        ),
      ],
    );
  }
}
