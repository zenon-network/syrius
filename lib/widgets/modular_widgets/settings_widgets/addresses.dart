import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:number_selector/number_selector.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_beneficiary_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class Addresses extends StatefulWidget {

  const Addresses({
    required this.accountChainStatsBloc,
    super.key,
  });
  final AccountChainStatsBloc accountChainStatsBloc;

  @override
  State createState() {
    return AddressesState();
  }
}

class AddressesState extends State<Addresses> {
  String? _selectedAddress = kSelectedAddress;

  Future<void>? _futureChangeDefaultAddress;

  Future<void>? _futureGenerateNewAddress;

  late ScrollController _scrollController;

  bool _shouldScrollToTheEnd = false;
  int numberOfAddressesToAdd = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Addresses',
      description: 'Select the default address that will be used throughout '
          'the wallet for any network operation',
      childBuilder: _getGenerateNewAddressFutureBuilder,
    );
  }

  Future<void> _changeDefaultAddress(String? newDefaultAddress) async {
    try {
      final box = Hive.box(kSharedPrefsBox);
      await box.put(kDefaultAddressKey, newDefaultAddress);
      if (!mounted) return;
      Provider.of<SelectedAddressNotifier>(
        context,
        listen: false,
      ).changeSelectedAddress(newDefaultAddress);
      Provider.of<PlasmaBeneficiaryAddressNotifier>(context, listen: false)
          .changePlasmaBeneficiaryAddress(
        newDefaultAddress,
      );
      widget.accountChainStatsBloc.updateStream();
      _selectedAddress = newDefaultAddress;
    } catch (e) {
      rethrow;
    }
  }

  Widget _getAddAddressWidget() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: NumberSelector.plain(
                borderColor: AppColors.znnColor,
                iconColor: AppColors.znnColor,
                dividerColor: AppColors.znnColor,
                current: 1,
                min: 1,
                max: 10,
                onUpdate: (val) {
                  _onAddAddressPressedCallback(val);
                },
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _futureGenerateNewAddress =
                    ZenonAddressUtils.generateNewAddress(
                        numAddr: numberOfAddressesToAdd,
                        callback: () {
                          setState(() {
                            _shouldScrollToTheEnd = true;
                          });
                        },);
              });
            },
            child: Container(
                constraints:
                    const BoxConstraints(minWidth: 150, minHeight: 50),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle,
                      color: AppColors.znnColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      (numberOfAddressesToAdd == 1)
                          ? 'Add $numberOfAddressesToAdd address  '
                          : 'Add $numberOfAddressesToAdd addresses',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _getAddresses() {
    final List<Widget> addresses = kDefaultAddressList
        .map(
          (e) => Row(
            children: [
              Radio<String?>(
                value: e,
                groupValue: _selectedAddress,
                onChanged: _onAddressPressedCallback,
              ),
              Expanded(
                child: SettingsAddress(
                  address: e,
                  onAddressLabelPressed: _onAddressPressedCallback,
                ),
              ),
            ],
          ),
        )
        .toList();

    final Widget listView = ListView.builder(
      controller: _scrollController,
      key: const PageStorageKey('Addresses list view'),
      shrinkWrap: true,
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        return addresses[index];
      },
    );

    if (_shouldScrollToTheEnd) {
      Timer(
        const Duration(milliseconds: 1),
        () {
          if (mounted && _scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
            _shouldScrollToTheEnd = false;
          }
        },
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: listView,
    );
  }

  Widget _getCardBody() {
    return Column(
      children: [
        Expanded(
          child: _getAddresses(),
        ),
        const Divider(),
        _getAddAddressWidget(),
      ],
    );
  }

  Widget _getGenerateNewAddressFutureBuilder() {
    return FutureBuilder(
      future: _futureGenerateNewAddress,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if ([
          ConnectionState.none,
          ConnectionState.done,
        ].contains(snapshot.connectionState)) {
          return _getChangeDefaultAddressFutureBuilder();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getChangeDefaultAddressFutureBuilder() {
    return FutureBuilder(
      future: _futureChangeDefaultAddress,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if ([
          ConnectionState.none,
          ConnectionState.done,
        ].contains(snapshot.connectionState)) {
          return _getCardBody();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  void _onAddAddressPressedCallback(int value) {
    setState(() {
      numberOfAddressesToAdd = value;
    });
  }

  void _onAddressPressedCallback(String? value) {
    setState(() {
      _futureChangeDefaultAddress = _changeDefaultAddress(value);
      numberOfAddressesToAdd = 1;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
