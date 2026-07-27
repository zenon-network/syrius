import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

// TODO(maznnwell): to be refactored, the controller should be just Text
class DisabledAddressField extends StatelessWidget {

  const DisabledAddressField(
    this._addressController, {
    this.contentLeftPadding = 8.0,
    super.key,
  });
  final TextEditingController _addressController;
  final double contentLeftPadding;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _addressController.text,
      child: TextField(
        enabled: false,
        controller: TextEditingController(
          text: kAddressLabelMap[_addressController.text],
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(left: contentLeftPadding),
        ),
      ),
    );
  }
}
