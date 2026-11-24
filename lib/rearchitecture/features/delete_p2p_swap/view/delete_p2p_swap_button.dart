import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/delete_p2p_swap/bloc/delete_p2p_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Button that handles deletion of a persisted P2P swap.
class DeleteP2pSwapButton extends StatelessWidget {
  /// Creates a [DeleteP2pSwapButton].
  const DeleteP2pSwapButton({required this.swapId, super.key});

  /// Identifier of the swap that should be deleted.
  final String swapId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeleteP2pSwapBloc>(
      create: (_) => DeleteP2pSwapBloc(
        swapRepository: sl<HtlcSwapRepository>(),
      ),
      child: BlocConsumer<DeleteP2pSwapBloc, DeleteP2pSwapState>(
        listener: (BuildContext context, DeleteP2pSwapState state) {
          if (state is DeleteP2pSwapFailure) {
            unawaited(
              NotificationUtils.sendNotificationError(
                state.exception,
                context.l10n.errorDeletingSwap,
              ),
            );
          }
        },
        builder: (BuildContext context, DeleteP2pSwapState state) {
          return switch (state) {
            DeleteP2pSwapLoading() => const Center(
              child: SyriusLoadingWidget(
                size: 20,
                strokeWidth: 2,
              ),
            ),
            _ => _buildButton(context),
          };
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return IconButton(
      onPressed: () => _onPressed(context),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.errorColor,
        padding: EdgeInsets.zero,
      ),
      tooltip: context.l10n.deleteSwap,
      icon: const Icon(Icons.delete_outline),
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    final DeleteP2pSwapBloc bloc = context.read<DeleteP2pSwapBloc>();
    final bool? deletionConfirmed = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: true,
      title: context.l10n.deleteSwap,
      description: context.l10n.deleteSwapCannotBeUndone,
    );

    if (deletionConfirmed ?? false) {
      bloc.add(DeleteP2pSwapRequested(swapId: swapId));
    }
  }
}
