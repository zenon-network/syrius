import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

// TODO(maznnwell): to be refactored, the controller should be just Text
/// Read-only address input displaying the address label with full tooltip.
class DisabledAddressField extends StatelessWidget {
  /// Creates a [DisabledAddressField].
  const DisabledAddressField(
    this._addressController, {
    this.contentLeftPadding = 8.0,
    this._labelText,
    super.key,
  });

  final TextEditingController _addressController;

  /// Left padding applied to the field's input decoration content.
  final double contentLeftPadding;
  final String? _labelText;

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
          labelText: _labelText,
        ),
      ),
    );
  }
}
