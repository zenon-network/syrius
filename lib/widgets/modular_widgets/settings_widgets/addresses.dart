import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:number_selector/number_selector.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_beneficiary_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class Addresses extends StatefulWidget {
  final AccountChainStatsBloc accountChainStatsBloc;

  const Addresses({
    required this.accountChainStatsBloc,
    Key? key,
  }) : super(key: key);

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
      childBuilder: () => _getGenerateNewAddressFutureBuilder(),
    );
  }

  Future<void> _changeDefaultAddress(String? newDefaultAddress) async {
    try {
      Box box = Hive.box(kSharedPrefsBox);
      await box.put(kDefaultAddressKey, newDefaultAddress);
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
      zenon!.defaultKeyPair = kKeyStore!.getKeyPair(
        kDefaultAddressList.indexOf(newDefaultAddress),
      );
    } catch (e) {
      rethrow;
    }
  }

  Widget _getAddAddressWidget() {
    int numAddrToAdd = 1;
    return InkWell(
      onTap: () {
        setState(() {
          _futureGenerateNewAddress = AddressUtils.generateNewAddress(
              numAddr: numAddrToAdd,
              callback: () {
                setState(() {
                  _shouldScrollToTheEnd = true;
                });
              });
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: NumberSelector.plain(
                  borderColor: AppColors.znnColor,
                  iconColor: AppColors.znnColor,
                  dividerColor: AppColors.znnColor,
                  step: 1,
                  current: 1,
                  min: 1,
                  max: 10,
                  onUpdate: (val) {
                    numAddrToAdd = val;
                  },
                ),
              ),
            ),
            const Icon(
              Icons.add_circle,
              color: AppColors.znnColor,
              size: 20.0,
            ),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 80),
              child: Text(
                'Add addresses',
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getAddresses() {
    List<Widget> addresses = kDefaultAddressList
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

    Widget listView = ListView.builder(
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
        const Duration(seconds: 1),
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

  void _onAddressPressedCallback(String? value) {
    setState(() {
      _futureChangeDefaultAddress = _changeDefaultAddress(value);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
