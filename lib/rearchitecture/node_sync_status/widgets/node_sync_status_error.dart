import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/node_sync_status/node_sync_status.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// A widget associated with the [NodeSyncStatusState] when it's status is
/// [CubitStatus.failure] that displays an icon with a tooltip message
class NodeSyncStatusError extends StatelessWidget {
  const NodeSyncStatusError({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: error.toString(),
      child: const Icon(
        Icons.sync_problem,
        size: 24,
        color: AppColors.errorColor,
      ),
    );
  }
}