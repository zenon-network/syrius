import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/node_sync_status/node_sync_status.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// A widget associated with the [NodeSyncStatusState] when it's status is
/// [CubitStatus.loading] that displays a loading indicator with a tooltip
class NodeSyncStatusLoading extends StatelessWidget {
  const NodeSyncStatusLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Loading status',
      child: SizedBox(
        height: 18,
        width: 18,
        child: Center(
          child: CircularProgressIndicator(
            backgroundColor: Theme.of(context).iconTheme.color,
            color: AppColors.znnColor,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}
