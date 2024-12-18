import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A widget that displays a loading indicator
class ReceiveInitial extends StatelessWidget {
  /// Creates a new instance.
  const ReceiveInitial({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
