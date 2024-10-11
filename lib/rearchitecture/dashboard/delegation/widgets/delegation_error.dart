import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

class DelegationError extends StatelessWidget {
  final Object error;

  const DelegationError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}
