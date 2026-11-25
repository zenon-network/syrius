import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays a wallet address row with inline label editing and copy action.
class SettingsAddressTile extends StatefulWidget {
  /// Creates a [SettingsAddressTile].
  const SettingsAddressTile({
    required this._address,
    required this._label,
    required this._isSavingLabel,
    required this._onAddressPressed,
    required this._onLabelSubmitted,
    super.key,
  });

  final String _address;
  final String _label;
  final bool _isSavingLabel;
  final ValueChanged<String> _onAddressPressed;
  final ValueChanged<String> _onLabelSubmitted;

  @override
  State<SettingsAddressTile> createState() => _SettingsAddressTileState();
}

class _SettingsAddressTileState extends State<SettingsAddressTile> {
  bool _editable = false;
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget._label);
  }

  @override
  void didUpdateWidget(covariant SettingsAddressTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._label != widget._label) {
      _labelController.text = widget._label;
      if (_editable) {
        _editable = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: _editable
          ? _buildAddressLabelInputField(context)
          : _buildAddressLabel(context),
    );
  }

  Widget _buildAddressLabel(BuildContext context) {
    final TextStyle bodyLarge = Theme.of(context).textTheme.bodyLarge!;
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => widget._onAddressPressed(widget._address),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget._label,
                    style: bodyLarge.copyWith(
                      color: bodyLarge.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  _buildAddressText(context),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        MaterialIconButton(
          size: 15,
          iconData: Icons.edit,
          onPressed: () {
            setState(() {
              _labelController.text = widget._label;
              _editable = true;
            });
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 5),
        CopyToClipboardButton(widget._address),
        const SizedBox(width: 5),
      ],
    );
  }

  Widget _buildAddressLabelInputField(BuildContext context) {
    final bool canSubmit =
        !widget._isSavingLabel && _labelController.text != widget._label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 40,
                child: InputField(
                  controller: _labelController,
                  onSubmitted: (String value) {
                    if (canSubmit) {
                      widget._onLabelSubmitted(_labelController.text);
                    }
                  },
                  onChanged: (String value) {
                    setState(() {});
                  },
                  inputtedTextStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: AppColors.znnColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentLeftPadding: 5,
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.znnColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            SettingsButton(
              onPressed: canSubmit
                  ? () => widget._onLabelSubmitted(_labelController.text)
                  : null,
              text: context.l10n.change,
            ),
            MaterialIconButton(
              size: 15,
              onPressed: () {
                setState(() {
                  _labelController.text = widget._label;
                  _editable = false;
                });
              },
              iconData: Icons.clear,
            ),
          ],
        ),
        _buildAddressText(context),
      ],
    );
  }

  Widget _buildAddressText(BuildContext context) {
    return Text(widget._address, style: Theme.of(context).textTheme.bodyMedium);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
}
