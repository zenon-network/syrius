import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

/// A widget that displays an error message
class ReceiveError extends StatelessWidget {
  /// Creates a new instance.
  const ReceiveError({required this.error, super.key});

  /// The field that holds the error message.
  final SyriusException error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error.message);
  }
}
