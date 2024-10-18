import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';

class PasswordProgressBar extends StatefulWidget {

  const PasswordProgressBar({
    required this.password,
    required this.passwordKey,
    super.key,
  });
  final String password;
  final GlobalKey<FormState> passwordKey;

  @override
  State<PasswordProgressBar> createState() => _PasswordProgressBarState();
}

class _PasswordProgressBarState extends State<PasswordProgressBar> {
  final List<Color> _colors = [
    AppColors.accessWalletContainersGray,
    AppColors.accessWalletContainersGray,
    AppColors.accessWalletContainersGray,
  ];

  @override
  Widget build(BuildContext context) {
    _getBarColors();

    return SizedBox(
      width: kPasswordInputFieldWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _getProgressBars().zip(_getSpacers()),
        ),
      ),
    );
  }

  List<Widget> _getProgressBars() => List.generate(
        _colors.length,
        (index) => _getPasswordProgressBar(_colors[index]),
      );

  List<Widget> _getSpacers() => List.generate(
        _colors.length - 1,
        (index) => _getSpacer(),
      );

  Expanded _getPasswordProgressBar(Color color) {
    return Expanded(
      child: Container(
        height: 5,
        color: color,
      ),
    );
  }

  SizedBox _getSpacer() {
    return const SizedBox(
      width: 10,
    );
  }

  void _getBarColors() {
    if (widget.password.isEmpty) {
      _colors[0] = AppColors.accessWalletContainersGray;
      _colors[1] = AppColors.accessWalletContainersGray;
      _colors[2] = AppColors.accessWalletContainersGray;
    } else if (widget.password.length < 8) {
      _colors[0] = AppColors.errorColor;
      _colors[1] = AppColors.accessWalletContainersGray;
      _colors[2] = AppColors.accessWalletContainersGray;
    } else if (widget.password.length >= 8 &&
        widget.password.length < 16 &&
        InputValidators.validatePassword(widget.password) == null) {
      _colors[0] = Colors.orange[300]!;
      _colors[1] = Colors.orange[300]!;
      _colors[2] = AppColors.accessWalletContainersGray;
    } else if (widget.password.length >= 16 &&
        InputValidators.validatePassword(widget.password) == null) {
      _colors[0] = AppColors.znnColor;
      _colors[1] = AppColors.znnColor;
      _colors[2] = AppColors.znnColor;
    }
  }
}

class ProgressBar extends StatelessWidget {

  const ProgressBar({
    required this.currentLevel,
    this.numLevels = 5,
    super.key,
  });
  final int currentLevel;
  final int numLevels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _getProgressBars().zip(_getSpacers()),
    );
  }

  List<Widget> _getProgressBars() => List.generate(
        numLevels,
        (index) => _getProgressBar(index + 1),
      );

  List<Widget> _getSpacers() => List.generate(
        numLevels - 1,
        (index) => _getSpacer(),
      );

  Container _getProgressBar(int level) {
    return Container(
      width: 125,
      height: 5,
      color: currentLevel >= level
          ? AppColors.znnColor
          : AppColors.accessWalletContainersGray,
    );
  }

  SizedBox _getSpacer() {
    return const SizedBox(
      width: 25,
    );
  }
}

class AcceleratorProgressBarSpan extends StatelessWidget {

  const AcceleratorProgressBarSpan({
    required this.value,
    required this.color,
    required this.tooltipMessage,
    super.key,
  });
  final double value;
  final Color color;
  final String tooltipMessage;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipMessage,
      child: Container(
        width: (value.isNaN ? 0 : value) * kAcceleratorProgressBarSize.width,
        height: kAcceleratorProgressBarSize.height,
        decoration: BoxDecoration(
          color: color,
        ),
      ),
    );
  }
}

class AcceleratorProgressBar extends StatelessWidget {

  const AcceleratorProgressBar(
      {required this.child, required this.context, super.key,});
  final Widget child;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: kAcceleratorProgressBarSize.width,
        height: kAcceleratorProgressBarSize.height,
        color: Theme.of(context).colorScheme.secondary,
        child: child,
      ),
    );
  }
}
