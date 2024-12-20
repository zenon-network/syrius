import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AddressCell extends StatelessWidget {
  const AddressCell({required this.address, super.key});

  final Address address;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableCell.textFromAddress(
      address: address,
    );
  }
}
