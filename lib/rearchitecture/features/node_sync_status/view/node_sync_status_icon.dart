import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';

/// A widget connected to the [NodeSyncStatusCubit] that receives the state
/// - [NodeSyncStatusState] - updates and rebuilds the UI according to the
/// state's status - [TimerStatus]
class NodeSyncStatusIcon extends StatelessWidget {
  /// Creates a NodeSyncStatusIcon object.
  const NodeSyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeSyncStatusCubit, NodeSyncStatusState>(
      builder: (BuildContext context, NodeSyncStatusState state) {
        return switch (state.status) {
          TimerStatus.initial => const NodeSyncStatusEmpty(),
          TimerStatus.failure => NodeSyncStatusError(
              error: state.error!,
            ),
          TimerStatus.loading => const NodeSyncStatusLoading(),
          TimerStatus.success => NodeSyncPopulated(data: state.data!),
        };
      },
    );
  }
}
