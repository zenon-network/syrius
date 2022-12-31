import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:znn_swap_utility/znn_swap_utility.dart';

class SwapTransferBalanceScreen extends StatefulWidget {
  final Pair<List<SwapAssetEntry>, List<SwapFileEntry>> _swapAssetsAndEntries;
  final String _passphrase;

  const SwapTransferBalanceScreen(
    this._swapAssetsAndEntries,
    this._passphrase, {
    Key? key,
  }) : super(key: key);

  @override
  State<SwapTransferBalanceScreen> createState() =>
      _SwapTransferBalanceScreenState();
}

class _SwapTransferBalanceScreenState extends State<SwapTransferBalanceScreen> {
  final List<TextEditingController> _currentAddressControllers = [];
  final List<TextEditingController> _newAddressControllers = [];
  final List<FocusNode> _currentAddressNode = [];
  final List<FocusNode> _newAddressNode = [];
  final List<SwapFileEntry> _swappedFileEntries = [];

  List<KeyPair>? _newKeyPairs;
  List<SwapAssetEntry>? _assetsAfterSwap;
  TransferBalanceBloc? _currentlyActiveModel;

  late List<SwapAssetEntry> _assetsBeforeSwap;
  late List<TransferBalanceBloc> _transferBalanceBlocs = [];
  late List<String> _selectedNewAddresses;
  late List<String?> _newAddressErrorTexts;

  bool? _shouldPerformCleanup;

  @override
  void initState() {
    super.initState();
    _assetsBeforeSwap = widget._swapAssetsAndEntries.first;
    if (_transferBalanceBlocs.isEmpty) {
      _transferBalanceBlocs = List.generate(
        widget._swapAssetsAndEntries.first.length,
        (index) => TransferBalanceBloc(),
      );
    }
    _initNewAddresses();
    _initNewAddressErrorTexts();
    _initSelectedNewAddresses();
    _shouldPerformCleanup =
        Directory(zenonDefaultLegacyDirectoryPath).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 30.0,
        ),
        child: Column(
          children: <Widget>[
            const ProgressBar(
              currentLevel: 4,
              numLevels: 4,
            ),
            const SizedBox(
              height: 30.0,
            ),
            Text(
              'Swap Wallet',
              style: Theme.of(context).textTheme.headline1,
            ),
            const SizedBox(
              height: 30.0,
            ),
            Expanded(
              child: _swapListWidget(
                widget._swapAssetsAndEntries.second
                    .map(
                      (e) => e.address,
                    )
                    .toList(),
              ),
            ),
            kVerticalSpacing,
            Visibility(
              visible: Directory(zenonDefaultLegacyDirectoryPath).existsSync(),
              child: _getPerformCleanupCheckBox(),
            ),
            kVerticalSpacing,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getGoBackButton(),
                const SizedBox(
                  width: 70.0,
                ),
                _getGoBackToSettingsButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getGoBackButton() {
    return OnboardingButton(
      text: 'Go back',
      onPressed: _currentlyActiveModel == null
          ? () {
              Navigator.pop(context);
            }
          : null,
    );
  }

  Widget _swapListWidget(List<String> oldAddresses) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 200.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(
          Radius.circular(
            20.0,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 30.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Legacy addresses',
                style: Theme.of(context).textTheme.bodyText1,
              ),
              Text(
                'Alphanet addresses',
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ],
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20.0),
              child: Form(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: oldAddresses.length,
                  itemBuilder: (context, index) {
                    _addInitialization();
                    return _swapCellWidget(
                      index,
                    );
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _addInitialization() {
    _currentAddressControllers.add(TextEditingController());
    _newAddressControllers.add(TextEditingController());
    _currentAddressNode.add(FocusNode());
    _newAddressNode.add(FocusNode());
  }

  Widget _swapCellWidget(int entryIndex) {
    String oldAddress = widget._swapAssetsAndEntries.second[entryIndex].address;

    bool isCellEnabled = !_swappedFileEntries
            .contains(widget._swapAssetsAndEntries.second[entryIndex]) &&
        (_assetsBeforeSwap[entryIndex].qsr > 0 ||
            _assetsBeforeSwap[entryIndex].znn > 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _getNumber(entryIndex + 1),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _oldAddressInputField(
                      entryIndex,
                      oldAddress,
                      isCellEnabled,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _getNewAddressDropdown(entryIndex, isCellEnabled),
                    _getNewAddressBalanceInfo(entryIndex),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: _getTransferBalanceWidget(
                  _transferBalanceBlocs[entryIndex],
                  entryIndex,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10.0,
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(),
              ),
              Expanded(
                flex: 4,
                child: isCellEnabled
                    ? _getOldAddressBalance(entryIndex)
                    : const Text('Swapped'),
              ),
              Expanded(
                flex: 4,
                child: _newAddressErrorTexts[entryIndex] != null
                    ? Text(
                        _newAddressErrorTexts[entryIndex] ?? '',
                        style: kTextFormFieldErrorStyle,
                      )
                    : _getNewAddressBalanceInfo(entryIndex),
              ),
              Expanded(
                flex: 1,
                child: Container(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Expanded _getNewAddressDropdown(index, bool isEnabled) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: AddressesDropdown(
              _selectedNewAddresses[index],
              isEnabled
                  ? (newAddress) {
                      setState(() {
                        _selectedNewAddresses[index] = newAddress!;
                      });
                    }
                  : null,
            ),
          ),
          CopyToClipboardIcon(
            _selectedNewAddresses[index],
          ),
        ],
      ),
    );
  }

  Widget _getNumber(number) {
    return Container(
      height: 35.0,
      width: 35.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondary,
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: Theme.of(context).textTheme.headline6,
      ),
    );
  }

  Widget _oldAddressInputField(index, String oldAddress, bool isCellEnabled) {
    TextEditingController controller = TextEditingController(text: oldAddress);

    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: InputField(
              enabled: false,
              hintText: 'Pillar reward address',
              controller: controller,
              thisNode: _currentAddressNode[index],
              nextNode: _newAddressNode[index],
              validator: (value) => InputValidators.notEmpty(
                'Pillar reward address',
                value,
              ),
              inputtedTextStyle:
                  Theme.of(context).textTheme.bodyText1!.copyWith(
                        color: isCellEnabled
                            ? AppColors.znnColor
                            : AppColors.lightSecondary,
                      ),
            ),
          ),
          CopyToClipboardIcon(oldAddress),
        ],
      ),
    );
  }

  Widget _getOldAddressBalance(index) {
    return _assetsAfterSwap == null
        ? Text(
            '${_assetsBeforeSwap[index].znn.addDecimals(
                  znnDecimals,
                )} ${kZnnCoin.symbol}, '
            '${_assetsBeforeSwap[index].qsr.addDecimals(
                  qsrDecimals,
                )} ${kQsrCoin.symbol}',
            style: const TextStyle(
              color: AppColors.znnColor,
            ),
          )
        : Container();
  }

  Widget _getNewAddressBalanceInfo(index) {
    return _assetsAfterSwap != null
        ? Text(
            '${_assetsBeforeSwap[index].znn - _assetsAfterSwap![index].znn} ${kZnnCoin.symbol}, '
            '${_assetsBeforeSwap[index].qsr - _assetsAfterSwap![index].qsr} ${kQsrCoin.symbol}',
            style: const TextStyle(
              color: AppColors.znnColor,
            ),
          )
        : Container();
  }

  Widget _getTransferBalanceWidget(TransferBalanceBloc model, int index) {
    model.stream.listen(
      (swapAssetEntryAfterSwap) {
        if (swapAssetEntryAfterSwap != null) {
          setState(() {
            _newAddressErrorTexts[index] = null;
            if (_currentlyActiveModel == model) {
              _currentlyActiveModel = null;
            }
          });
        }
      },
      onError: (error) {
        setState(() {
          _newAddressErrorTexts[index] = error.toString();
          _currentlyActiveModel = null;
        });
      },
    );

    return Row(
      children: [
        StreamBuilder<SwapFileEntry?>(
          stream: model.stream,
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return _getTransferBalanceIcon(model, index);
            }
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                _swappedFileEntries.add(snapshot.data!);
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.check,
                    color: AppColors.znnColor,
                  ),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SyriusLoadingWidget(
                    size: 15.0,
                  ),
                );
              }
            }
            return _getTransferBalanceIcon(model, index);
          },
        ),
      ],
    );
  }

  Widget _getTransferBalanceIcon(TransferBalanceBloc model, int index) {
    return RawMaterialButton(
      child: Icon(
        MaterialCommunityIcons.swap_horizontal,
        color: _ifBalanceIsAvailable(index) && _currentlyActiveModel == null
            ? AppColors.znnColor
            : Theme.of(context).disabledColor,
      ),
      constraints: const BoxConstraints.tightForFinite(),
      padding: const EdgeInsets.all(8),
      shape: const CircleBorder(),
      onPressed: _ifBalanceIsAvailable(index) && _currentlyActiveModel == null
          ? () async {
              setState(() {
                _currentlyActiveModel = model;
              });
              model.transferBalanceToNewAddresses(
                widget._swapAssetsAndEntries.second[index],
                _getKeyPairForNewAddress(index),
                widget._passphrase,
              );
            }
          : null,
    );
  }

  void _initNewAddressErrorTexts() {
    _newAddressErrorTexts = List.generate(
      _newKeyPairs!.length,
      (index) => null,
    );
  }

  Widget _getGoBackToSettingsButton() {
    return OnboardingButton(
      onPressed: _currentlyActiveModel == null ? _onFinishButtonPressed : null,
      text: 'Finish',
    );
  }

  void _onFinishButtonPressed() {
    Navigator.popUntil(
      context,
      ModalRoute.withName(MainAppContainer.route),
    );
    if (_shouldPerformCleanup ?? false) {
      _removeLegacyData().then(
          (value) => sl.get<NotificationsBloc>().addNotification(
                WalletNotification(
                  title: 'Successful cleanup',
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  details: 'Successfully removed legacy data',
                  type: NotificationType.delete,
                ),
              ), onError: (error) {
        NotificationUtils.sendNotificationError(
            error, 'Couldn\'t remove legacy data');
      });
    }
  }

  bool _ifBalanceIsAvailable(int oldAddressIndex) =>
      _assetsBeforeSwap[oldAddressIndex].znn > 0 ||
      _assetsBeforeSwap[oldAddressIndex].qsr > 0;

  Future<KeyPair?> _getKeyPairForNewAddress(int index) async =>
      (await kKeyStore!.findAddress(
        Address.parse(
          _selectedNewAddresses[index],
        ),
        kDefaultAddressList.length,
      ))!
          .keyPair;

  void _initSelectedNewAddresses() => _selectedNewAddresses = List.generate(
        widget._swapAssetsAndEntries.first.length,
        (index) => kDefaultAddressList[index]!,
      );

  void _initNewAddresses() {
    _newKeyPairs = List.generate(
      widget._swapAssetsAndEntries.second.length,
      (index) => kKeyStore!.getKeyPair(index),
    );
  }

  Widget _getPerformCleanupCheckBox() {
    return Visibility(
      visible: _ifThereIsNothingToSwap(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Checkbox(
            checkColor: Theme.of(context).scaffoldBackgroundColor,
            activeColor: AppColors.znnColor,
            value: _shouldPerformCleanup,
            onChanged: (value) {
              setState(() {
                _shouldPerformCleanup = value;
              });
            },
          ),
          Text(
            'In order to avoid incompatibilities, remove legacy data',
            style: Theme.of(context).textTheme.bodyText2,
          )
        ],
      ),
    );
  }

  bool _ifThereIsNothingToSwap() {
    for (int i = 0; i < _assetsBeforeSwap.length; i++) {
      if (_assetsBeforeSwap[i].znn > 0 || _assetsBeforeSwap[i].qsr > 0) {
        if (!_swappedFileEntries
            .contains(widget._swapAssetsAndEntries.second[i])) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void dispose() {
    for (var controller in _currentAddressControllers) {
      controller.dispose();
    }
    for (var controller in _newAddressControllers) {
      controller.dispose();
    }
    for (var focusNode in _currentAddressNode) {
      focusNode.dispose();
    }
    for (var focusNode in _newAddressNode) {
      focusNode.dispose();
    }
    for (var bloc in _transferBalanceBlocs) {
      bloc.dispose();
    }
    _currentlyActiveModel?.dispose();
    _cleanupAfterSwapFinished();
    super.dispose();
  }

  void _cleanupAfterSwapFinished() async {
    try {
      String swapWalletTempDirectoryPath = path.join(
        znnDefaultDirectory.path,
        kSwapWalletTempDirectory,
      );
      await FileUtils.deleteDirectory(
        swapWalletTempDirectoryPath,
      );
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Error while cleaning up files after swap',
      );
    }
  }

  Future<void> _removeLegacyData() async {
    List<FileSystemEntity> files = Directory(zenonDefaultLegacyDirectoryPath)
        .listSync(recursive: true, followLinks: true);
    for (FileSystemEntity file in files) {
      String fileName = File(file.absolute.path).uri.pathSegments.last;
      if (file.existsSync() &&
          !fileName.contains('wallet') &&
          !fileName.contains('backups')) {
        file.deleteSync(recursive: true);
      }
    }
  }

  String _getDefaultZenonLegacyDirectoryLocation() {
    if (Platform.isWindows) {
      return Platform.environment['AppData']!;
    } else if (Platform.isMacOS) {
      return path.join(
          Platform.environment['HOME']!, 'Library', 'Application Support');
    } else {
      return Platform.environment['HOME']!;
    }
  }

  String get zenonDefaultLegacyDirectoryPath => path.join(
        _getDefaultZenonLegacyDirectoryLocation(),
        _getZenonLegacyDirectoryName(),
      );

  String _getZenonLegacyDirectoryName() {
    if (Platform.isLinux) {
      return '.Zenon';
    } else {
      return 'Zenon';
    }
  }
}
