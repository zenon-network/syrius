import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

/// A single weighted segment inside an [AcceleratorVotingProgressBar].
class AcceleratorVotingProgressBarSpan extends StatelessWidget {
  /// Creates an [AcceleratorVotingProgressBarSpan].
  const AcceleratorVotingProgressBarSpan({
    required this._value,
    required this._color,
    required this._tooltipMessage,
    super.key,
  });

  final double _value;
  final Color _color;
  final String _tooltipMessage;

  @override
  Widget build(BuildContext context) {
    final double safeFraction = _value.isNaN || _value.isInfinite
        ? 0.0
        : _value.clamp(0.0, 1.0);

    return Tooltip(
      message: _tooltipMessage,
      child: Container(
        width: safeFraction * kAcceleratorProgressBarSize.width,
        height: kAcceleratorProgressBarSize.height,
        color: _color,
      ),
    );
  }
}

/// Rounded horizontal progress bar for displaying Accelerator vote ratios.
class AcceleratorVotingProgressBar extends StatelessWidget {
  /// Creates an [AcceleratorVotingProgressBar].
  const AcceleratorVotingProgressBar({required this._child, super.key});

  final Widget _child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: kAcceleratorProgressBarSize.width,
        height: kAcceleratorProgressBarSize.height,
        color: Theme.of(context).colorScheme.secondary,
        child: _child,
      ),
    );
  }
}
