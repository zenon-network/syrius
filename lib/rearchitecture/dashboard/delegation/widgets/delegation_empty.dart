import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';

class DelegationEmpty extends StatelessWidget {
  const DelegationEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusErrorWidget('No data available');
  }
}