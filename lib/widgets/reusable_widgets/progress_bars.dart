import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/password_strength_utils.dart';

/// Three-segment strength indicator bar for a wallet password.
class PasswordProgressBar extends StatefulWidget {
  /// Creates a [PasswordProgressBar].
  const PasswordProgressBar({
    required this.password,
    required this.passwordKey,
    super.key,
  });

  /// Current password text evaluated for strength.
  final String password;

  /// Form key associated with the password input field.
  final GlobalKey<FormState> passwordKey;

  @override
  State<PasswordProgressBar> createState() => _PasswordProgressBarState();
}

class _PasswordProgressBarState extends State<PasswordProgressBar> {
  final List<Color> _colors = <Color>[
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

  List<Widget> _getProgressBars() => List<Widget>.generate(
        _colors.length,
        (int index) => _getPasswordProgressBar(_colors[index]),
      );

  List<Widget> _getSpacers() => List<Widget>.generate(
        _colors.length - 1,
        (int index) => _getSpacer(),
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
    final PasswordStrengthTier tier = classifyPasswordStrength(
      widget.password,
      isValid: InputValidators.validatePassword(widget.password) == null,
    );
    switch (tier) {
      case PasswordStrengthTier.empty:
        _colors[0] = AppColors.accessWalletContainersGray;
        _colors[1] = AppColors.accessWalletContainersGray;
        _colors[2] = AppColors.accessWalletContainersGray;
      case PasswordStrengthTier.weak:
        _colors[0] = AppColors.errorColor;
        _colors[1] = AppColors.accessWalletContainersGray;
        _colors[2] = AppColors.accessWalletContainersGray;
      case PasswordStrengthTier.medium:
        _colors[0] = Colors.orange[300]!;
        _colors[1] = Colors.orange[300]!;
        _colors[2] = AppColors.accessWalletContainersGray;
      case PasswordStrengthTier.strong:
        _colors[0] = AppColors.znnColor;
        _colors[1] = AppColors.znnColor;
        _colors[2] = AppColors.znnColor;
    }
  }
}

/// Segmented horizontal progress bar highlighting up to [currentLevel].
class ProgressBar extends StatelessWidget {
  /// Creates a [ProgressBar].
  const ProgressBar({
    required this.currentLevel,
    this.numLevels = 5,
    super.key,
  });

  /// Number of completed segments to highlight.
  final int currentLevel;

  /// Total number of segments rendered.
  final int numLevels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _getProgressBars().zip(_getSpacers()),
    );
  }

  List<Widget> _getProgressBars() => List<Widget>.generate(
        numLevels,
        (int index) => _getProgressBar(index + 1),
      );

  List<Widget> _getSpacers() => List<Widget>.generate(
        numLevels - 1,
        (int index) => _getSpacer(),
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

/// Proportional colored segment inside an [AcceleratorProgressBar].
class AcceleratorProgressBarSpan extends StatelessWidget {
  /// Creates an [AcceleratorProgressBarSpan].
  const AcceleratorProgressBarSpan({
    required this.value,
    required this.color,
    required this.tooltipMessage,
    super.key,
  });

  /// Fraction of the total progress bar width represented by this span.
  final double value;

  /// Fill color of this span.
  final Color color;

  /// Tooltip text describing this span's value.
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

/// Rounded container framing spans for an Accelerator-Z voting progress bar.
class AcceleratorProgressBar extends StatelessWidget {
  /// Creates an [AcceleratorProgressBar].
  const AcceleratorProgressBar({
    required this.child,
    required this.context,
    super.key,
  });

  /// Content widget (typically a row of [AcceleratorProgressBarSpan]s).
  final Widget child;

  /// Build context associated with the caller.
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
