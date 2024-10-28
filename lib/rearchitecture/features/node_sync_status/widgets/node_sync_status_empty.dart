import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';

/// A widget associated with the [NodeSyncStatusState] when it's status is
/// [TimerStatus.initial] that displays an icon with a tooltip message
class NodeSyncStatusEmpty extends StatelessWidget {
  /// Creates a NodeSyncStatusEmpty object.
  const NodeSyncStatusEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Not ready',
      child: Icon(
        Icons.sync_disabled,
        size: 24,
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}
