import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/cancel_stake/bloc/cancel_stake_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Button that handles the stake cancellation flow.
class CancelStakeButton extends StatelessWidget {
  /// Creates a [CancelStakeButton].
  const CancelStakeButton({
    required this.stakeHash,
    required this.onCancelled,
    super.key,
  });

  /// Hash of the stake entry that should be cancelled.
  final Hash stakeHash;

  /// Called after the stake cancellation succeeds.
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CancelStakeBloc>(
      create: (_) => CancelStakeBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: Row(
        mainAxisAlignment: .center,
        mainAxisSize: .min,
        children: <Widget>[
          BlocConsumer<CancelStakeBloc, CancelStakeState>(
            listener: (BuildContext context, CancelStakeState state) {
              if (state is CancelStakeDone) {
                onCancelled();
              } else if (state is CancelStakeFailure) {
                unawaited(
                  NotificationUtils.sendNotificationError(
                    state.exception,
                    context.l10n.errorWhileCancellingStake,
                  ),
                );
              }
            },
            builder: (BuildContext context, CancelStakeState state) {
              return switch (state) {
                CancelStakeLoading() => const SyriusLoadingWidget(size: 25),
                _ => _buildButton(context),
              };
            },
          ),
        ],
      ),
    );
  }

  OutlinedButton _buildButton(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        iconColor: AppColors.errorColor,
        side: const BorderSide(color: AppColors.errorColor),
      ),
      onPressed: () async {
        final CancelStakeBloc cancelStakeBloc = context.read<CancelStakeBloc>();
        final bool? cancellationConfirmed = await showDialogWithNoAndYesOptions(
          isBarrierDismissible: false,
          context: context,
          title: context.l10n.cancel.toUpperCase(),
          // TODO(maznnwell): localize if the description is okay
          description: 'Are you sure you want to cancel the stake?',
        );

        if (cancellationConfirmed ?? false) {
          cancelStakeBloc.add(
            CancelStakeRequested(stakeHash: stakeHash),
          );
        }
      },
      label: Text(
        context.l10n.cancel.toUpperCase(),
        style: TextStyle(
          color: context.newThemeData.textTheme.titleSmall!.color,
        ),
      ),
      icon: const Icon(Icons.close),
    );
  }
}
