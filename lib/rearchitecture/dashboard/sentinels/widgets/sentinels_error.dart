import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [SentinelsState] when it's status is
/// [CubitStatus.error] that uses the [SyriusErrorWidget] to display a message
class SentinelsError extends StatelessWidget {

  const SentinelsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}
