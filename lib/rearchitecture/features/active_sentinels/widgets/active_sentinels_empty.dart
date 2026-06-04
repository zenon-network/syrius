import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [ActiveSentinelsState] when its status is
/// [TimerStatus.initial] that uses the [SyriusErrorWidget] to display a
/// message
class ActiveSentinelsEmpty extends StatelessWidget {
  /// Creates an [ActiveSentinelsEmpty].
  const ActiveSentinelsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(context.l10n.waitingForDataFetching);
  }
}
