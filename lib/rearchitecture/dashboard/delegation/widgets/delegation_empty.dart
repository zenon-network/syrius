import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

/// A widget that displays a hardcoded error message
class DelegationEmpty extends StatelessWidget {
  /// Creates a DelegationEmpty object.
  const DelegationEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusErrorWidget('No data available');
  }
}
