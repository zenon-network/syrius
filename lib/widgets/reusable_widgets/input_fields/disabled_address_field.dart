import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class DisabledAddressField extends StatelessWidget {
  final TextEditingController _addressController;
  final double contentLeftPadding;

  const DisabledAddressField(
    this._addressController, {
    this.contentLeftPadding = 8.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _addressController.text,
      child: InputField(
        enabled: false,
        controller: TextEditingController(
          text: kAddressLabelMap[_addressController.text],
        ),
        contentLeftPadding: contentLeftPadding,
      ),
    );
  }
}
