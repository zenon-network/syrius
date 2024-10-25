import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/node_sync_status/node_sync_status.dart';

/// A widget associated with the [NodeSyncStatusState] when it's status is
/// [DashboardStatus.initial] that displays an icon with a tooltip message
class NodeSyncStatusEmpty extends StatelessWidget {
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
