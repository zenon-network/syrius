import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/cancel_plasma/bloc/cancel_plasma_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Button that handles the Plasma cancellation flow.
class CancelPlasmaButton extends StatelessWidget {
  /// Creates a [CancelPlasmaButton].
  const CancelPlasmaButton({
    required this.plasmaHash,
    required this.onCancelled,
    super.key,
  });

  /// Hash of the Plasma fusion entry that should be cancelled.
  final Hash plasmaHash;

  /// Called after the Plasma cancellation succeeds.
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CancelPlasmaBloc>(
      create: (_) => CancelPlasmaBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: Row(
        mainAxisAlignment: .center,
        mainAxisSize: .min,
        children: <Widget>[
          BlocConsumer<CancelPlasmaBloc, CancelPlasmaState>(
            listener: (BuildContext context, CancelPlasmaState state) {
              if (state is CancelPlasmaDone) {
                onCancelled();
              } else if (state is CancelPlasmaFailure) {
                unawaited(
                  NotificationUtils.sendNotificationError(
                    state.exception,
                    context.l10n.errorWhileCancellingPlasma,
                  ),
                );
              }
            },
            builder: (BuildContext context, CancelPlasmaState state) {
              return switch (state) {
                CancelPlasmaLoading() => const SyriusLoadingWidget(size: 25),
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
        final CancelPlasmaBloc cancelPlasmaBloc = context
            .read<CancelPlasmaBloc>();
        final bool? cancellationConfirmed = await showDialogWithNoAndYesOptions(
          isBarrierDismissible: false,
          context: context,
          title: context.l10n.cancel,
          description: context.l10n.cancelPlasmaConfirmation,
        );

        if (cancellationConfirmed ?? false) {
          cancelPlasmaBloc.add(
            CancelPlasmaRequested(plasmaHash: plasmaHash),
          );
        }
      },
      label: Text(
        context.l10n.cancel,
        style: TextStyle(
          color: context.newThemeData.textTheme.titleSmall!.color,
        ),
      ),
      icon: const Icon(Icons.close),
    );
  }
}
