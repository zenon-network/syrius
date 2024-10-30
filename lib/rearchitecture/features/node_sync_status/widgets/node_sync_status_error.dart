import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// A widget associated with the [NodeSyncStatusState] when it's status is
/// [TimerStatus.failure] that displays an icon with a tooltip message
class NodeSyncStatusError extends StatelessWidget {
  /// Creates a NodeSyncStatusError object.
  const NodeSyncStatusError({required this.error, super.key});

  /// Error that holds the message used in the [Tooltip]
  final SyriusException error;

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
