import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A custom [LoadingButton] that has a fixed horizontal padding around the
/// child widget
class SendButton extends LoadingButton {
  /// Creates a new instance, with a default [minimumSize]
  const SendButton({
    required super.onPressed,
    required super.key,
    required super.text,
    super.minimumSize = const Size(100, 48),
  }) : super(
          paddingAroundChild: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
        );
}
