import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
    return InkWell(
      onTap: () {
        setState(() {
          _futureGenerateNewAddress =
              AddressUtils.generateNewAddress(callback: () {
            setState(() {
              _shouldScrollToTheEnd = true;
            });
          });
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle,
              color: AppColors.znnColor,
              size: 20.0,
            ),
            const SizedBox(
              width: 5.0,
            ),
            Text(
              'Add new address',
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getAddresses() {
    List<Widget> _addresses = kDefaultAddressList
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
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        return _addresses[index];
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
