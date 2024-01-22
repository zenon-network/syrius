import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class HardwareWalletDeviceChoiceScreen extends StatefulWidget {
  const HardwareWalletDeviceChoiceScreen({Key? key}) : super(key: key);

  @override
  State<HardwareWalletDeviceChoiceScreen> createState() =>
      _HardwareWalletDeviceChoiceScreenState();
}

class _HardwareWalletDeviceChoiceScreenState
    extends State<HardwareWalletDeviceChoiceScreen> {
  final List<WalletManager> _walletManagers = [LedgerWalletManager()];
  List<WalletDefinition> _devices = [];
  WalletDefinition? _selectedDevice;
  final Map<String, ValueNotifier<String?>> _deviceValueMap =
      <String, ValueNotifier<String?>>{};

  @override
  void initState() {
    super.initState();
    _openHiveAddressesBox();
  }

  void _openHiveAddressesBox() {
    Hive.boxExists(kAddressesBox).then(
      (bool addressesBoxExists) {
        if (addressesBoxExists) {
          Hive.openBox(kAddressesBox)
              .then((Box addressesBox) => addressesBox.clear());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: [
                const ProgressBar(
                  currentLevel: 1,
                  numLevels: 4,
                ),
                const SizedBox(
                  height: 30.0,
                ),
                Text(
                  'Choose your device',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                kVerticalSpacing,
                Text(
                  'Please connect and unlock your device',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                kVerticalSpacing,
                SizedBox(
                  height: 40.0,
                  child: _getScanDevicesContainer(),
                ),
                kVerticalSpacing,
                SizedBox(
                  width: 420,
                  child: Column(children: _getDevices()),
                ),
              ],
            ),
            _getActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _getScanDevicesContainer() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
          border: Border.all(
            color: AppColors.znnColor,
            width: 1.0,
            style: BorderStyle.solid,
          )),
      child: InkWell(
          child: FocusableActionDetector(
            child: SizedBox(
              height: 50.0,
              width: 150.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      color: Colors.transparent,
                      child: Icon(Icons.search,
                          color:
                              Theme.of(context).textTheme.headlineSmall!.color!,
                          size: 18.0)),
                  const SizedBox(
                    width: 15.0,
                  ),
                  Text(
                    'Scan devices',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          onTap: () async {
            await _scanDevices();
          }),
    );
  }

  Future<void> _scanDevices() async {
    List<Future<Iterable<WalletDefinition>>> futures = _walletManagers
        .map((manager) => manager.getWalletDefinitions())
        .toList();

    List<Iterable<WalletDefinition>> listOfDefinitions =
        await Future.wait(futures);

    // Combine all the iterables into a single list using fold or expand
    // For example, using fold:
    List<WalletDefinition> combinedList =
        listOfDefinitions.fold<List<WalletDefinition>>(
      <WalletDefinition>[],
      (previousList, element) => previousList..addAll(element),
    );

    for (var device in combinedList) {
      if (!_deviceValueMap.containsKey(device.walletId)) {
        _deviceValueMap[device.walletId] = ValueNotifier<String?>(null);
      }
    }

    setState(() {
      _devices = combinedList;
      _selectedDevice = null;

      for (var valueNotifier in _deviceValueMap.values) {
        valueNotifier.value = null;
      }
    });
  }

  List<Widget> _getDevices() {
    return _devices
        .map(
          (e) => Row(
            children: [
              Radio<WalletDefinition?>(
                value: e,
                groupValue: _selectedDevice,
                onChanged: _onDevicePressedCallback,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 5.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            10.0,
                          ),
                          onTap: () => _onDevicePressedCallback(e),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5.0, vertical: 5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getWalletName(e),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!
                                            .withOpacity(0.7),
                                      ),
                                ),
                                ValueListenableBuilder<String?>(
                                  valueListenable: _deviceValueMap[e.walletId]!,
                                  builder: (context, value, _) => SizedBox(
                                    height: 20,
                                    child: value == null
                                        ? const Text(
                                            'select to connect the device')
                                        : Text(value,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
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
              )
            ],
          ),
        )
        .toList();
  }

  Future<void> _onDevicePressedCallback(
      WalletDefinition? walletDefinition) async {
    Wallet? wallet;
    try {
      for (var walletManager in _walletManagers) {
        WalletDefinition wd = walletDefinition!;
        if (await walletManager.supportsWallet(wd)) {
          wallet = await walletManager.getWallet(walletDefinition);
          break;
        }
      }
      if (wallet == null) {
        throw const LedgerError.connectionError(
            origMessage:
                'not connected, please connect the device and try again.');
      }
      final walletAccount = await wallet.getAccount();
      final walletAddress = await walletAccount.getAddress();
      setState(() {
        _deviceValueMap[walletDefinition!.walletId]!.value =
            walletAddress.toString();
        _selectedDevice = walletDefinition;
      });
    } catch (e) {
      _mapError(walletDefinition, e);
    } finally {
      if (wallet != null) {
        try {
          await (wallet as LedgerWallet).disconnect();
        } catch (_) {}
      }
      wallet = null;
    }
  }

  void _mapError(WalletDefinition? walletDefinition, Object err) {
    String? errorText;
    if (err is LedgerError) {
      errorText = err.toFriendlyString();
    } else {
      errorText = 'error: $err';
    }
    setState(() {
      _deviceValueMap[walletDefinition!.walletId]!.value = errorText;
      _selectedDevice = null;
    });
  }

  String _getWalletName(WalletDefinition walletDefinition) {
    if (walletDefinition is LedgerWalletDefinition) {
      return 'Ledger ${walletDefinition.walletName}';
    }
    return walletDefinition.walletName;
  }

  Widget _getActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        OnboardingButton(
          onPressed: () {
            Navigator.pop(context);
          },
          text: 'Go back',
        ),
        kSpacingBetweenActionButtons,
        OnboardingButton(
          onPressed: _selectedDevice != null
              ? () {
                  NavigationUtils.push(
                    context,
                    HardwareWalletPasswordScreen(_selectedDevice!.walletId),
                  );
                }
              : null,
          text: 'Continue',
        ),
      ],
    );
  }
}
