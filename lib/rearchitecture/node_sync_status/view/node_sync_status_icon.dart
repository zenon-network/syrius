import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/node_sync_status/node_sync_status.dart';

/// A widget connected to the [NodeSyncStatusCubit] that receives the state
/// - [NodeSyncStatusState] - updates and rebuilds the UI according to the
/// state's status - [DashboardStatus]
class NodeSyncStatusIcon extends StatelessWidget {
  const NodeSyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeSyncStatusCubit, NodeSyncStatusState>(
      builder: (context, state) {
        return switch (state.status) {
          DashboardStatus.initial => const NodeSyncStatusEmpty(),
          DashboardStatus.failure => NodeSyncStatusError(
            error: state.error!,
          ),
          DashboardStatus.loading => const NodeSyncStatusLoading(),
          DashboardStatus.success => NodeSyncPopulated(data: state.data!),
        };
      },
    );
  }
}
