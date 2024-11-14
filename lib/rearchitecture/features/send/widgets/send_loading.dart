import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A widget that display a loading indicator.
class SendLoading extends StatelessWidget {
  /// Creates a new instance.
  const SendLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
