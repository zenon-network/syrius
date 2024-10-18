import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SettingsAddress extends StatefulWidget {

  const SettingsAddress({
    required this.address,
    required this.onAddressLabelPressed,
    super.key,
  });
  final String? address;
  final void Function(String?) onAddressLabelPressed;

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
        vertical: 5,
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
              10,
            ),
            onTap: () => widget.onAddressLabelPressed(widget.address),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
          width: 5,
        ),
        MaterialIconButton(
          size: 15,
          iconData: Icons.edit,
          onPressed: () {
            setState(() {
              _editable = true;
            });
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(
          width: 5,
        ),
        CopyToClipboardIcon(
          widget.address,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(
          width: 5,
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
                height: 40,
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentLeftPadding: 5,
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
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
            const SizedBox(
              width: 15,
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
              size: 15,
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

  Future<void> _onChangeButtonPressed() async {
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
        await NotificationUtils.sendNotificationError(
          "Label can't be empty",
          "Label can't be empty",
        );
      } else if (_labelController.text.length > kAddressLabelMaxLength) {
        await NotificationUtils.sendNotificationError(
          'The label ${_labelController.text} is ${_labelController.text.length} '
              'characters long, which is more than the $kAddressLabelMaxLength limit.',
          'The label has more than $kAddressLabelMaxLength characters',
        );
      } else {
        await NotificationUtils.sendNotificationError(
          'Label ${_labelController.text}'
              ' already exists in the database',
          'Label already exists',
        );
      }
    } catch (e) {
      await NotificationUtils.sendNotificationError(
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
