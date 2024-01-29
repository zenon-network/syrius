import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SettingsAddress extends StatefulWidget {
  final String? address;
  final void Function(String?) onAddressLabelPressed;

  const SettingsAddress({
    required this.address,
    required this.onAddressLabelPressed,
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsAddress> createState() => _SettingsAddressState();
}

class _SettingsAddressState extends State<SettingsAddress> {
  bool _editable = false;

  final TextEditingController _labelController = TextEditingController();

  final GlobalKey<MyOutlinedButtonState> _changeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (kAddressLabelMap[widget.address] != null) {
      _labelController.text = kAddressLabelMap[widget.address]!;
    } else {
      _labelController.text = 'Address 1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 5.0,
      ),
      child:
          _editable ? _getAddressLabelInputField() : _getAddressLabel(context),
    );
  }

  Row _getAddressLabel(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(
              10.0,
            ),
            onTap: () => widget.onAddressLabelPressed(widget.address),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelController.text,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withOpacity(0.7),
                        ),
                  ),
                  _getAddressTextWidget(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 5.0,
        ),
        MaterialIconButton(
          iconData: Icons.edit,
          onPressed: () {
            setState(() {
              _editable = true;
            });
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(
          width: 5.0,
        ),
        CopyToClipboardIcon(
          widget.address,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(
          width: 5.0,
        ),
      ],
    );
  }

  Widget _getAddressLabelInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40.0,
                child: InputField(
                  controller: _labelController,
                  onSubmitted: (value) {
                    if (_labelController.text !=
                        kAddressLabelMap[widget.address]!) {
                      _onChangeButtonPressed();
                    }
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                  inputtedTextStyle:
                      Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: AppColors.znnColor,
                          ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentLeftPadding: 5.0,
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.znnColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 2.0,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 15.0,
            ),
            SettingsButton(
              onPressed:
                  _labelController.text != kAddressLabelMap[widget.address]!
                      ? _onChangeButtonPressed
                      : null,
              text: 'Change',
              key: _changeButtonKey,
            ),
            MaterialIconButton(
              onPressed: () {
                setState(() {
                  _labelController.text = kAddressLabelMap[widget.address]!;
                  _editable = false;
                });
              },
              iconData: Icons.clear,
            ),
          ],
        ),
        _getAddressTextWidget(),
      ],
    );
  }

  Text _getAddressTextWidget() {
    return Text(
      widget.address!,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  void _onChangeButtonPressed() async {
    try {
      _changeButtonKey.currentState!.showLoadingIndicator(true);
      if (_labelController.text.isNotEmpty &&
          _labelController.text.length <= kAddressLabelMaxLength &&
          !kAddressLabelMap.containsValue(_labelController.text)) {
        await Hive.box(kAddressLabelsBox).put(
          widget.address,
          _labelController.text,
        );
        kAddressLabelMap[widget.address!] = _labelController.text;
        setState(() {
          _editable = false;
        });
      } else if (_labelController.text.isEmpty) {
        NotificationUtils.sendNotificationError(
          'Label can\'t be empty',
          'Label can\'t be empty',
        );
      } else if (_labelController.text.length > kAddressLabelMaxLength) {
        NotificationUtils.sendNotificationError(
          'The label ${_labelController.text} is ${_labelController.text.length} '
              'characters long, which is more than the $kAddressLabelMaxLength limit.',
          'The label has more than $kAddressLabelMaxLength characters',
        );
      } else {
        NotificationUtils.sendNotificationError(
          'Label ${_labelController.text}'
              ' already exists in the database',
          'Label already exists',
        );
      }
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Something went wrong while changing the address label',
      );
    } finally {
      _changeButtonKey.currentState!.showLoadingIndicator(false);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
}
