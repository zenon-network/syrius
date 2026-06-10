import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/revoke_sentinel/bloc/revoke_sentinel_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Button that handles the sentinel revoke/disassemble flow.
class RevokeSentinelButton extends StatelessWidget {
  /// Creates a [RevokeSentinelButton].
  const RevokeSentinelButton({
    required this.onRevoked,
    super.key,
  });

  /// Called after the sentinel revoke operation succeeds.
  final VoidCallback onRevoked;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RevokeSentinelBloc>(
      create: (_) => RevokeSentinelBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: Row(
        mainAxisAlignment: .center,
        mainAxisSize: .min,
        children: <Widget>[
          BlocConsumer<RevokeSentinelBloc, RevokeSentinelState>(
            listener: (BuildContext context, RevokeSentinelState state) {
              if (state is RevokeSentinelDone) {
                onRevoked();
              } else if (state is RevokeSentinelFailure) {
                unawaited(
                  NotificationUtils.sendNotificationError(
                    state.exception,
                    context.l10n.errorDisassemblingSentinel,
                  ),
                );
              }
            },
            builder: (BuildContext context, RevokeSentinelState state) {
              return switch (state) {
                RevokeSentinelLoading() => const SyriusLoadingWidget(size: 25),
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
        final RevokeSentinelBloc revokeSentinelBloc = context
            .read<RevokeSentinelBloc>();
        final bool? revocationConfirmed = await showDialogWithNoAndYesOptions(
          isBarrierDismissible: false,
          context: context,
          title: context.l10n.disassemble,
          // TODO(maznnwell): localize if the description is okay
          description: 'Are you sure you want to revoke the sentinel?',
        );

        if (revocationConfirmed ?? false) {
          revokeSentinelBloc.add(
            const RevokeSentinelRequested(),
          );
        }
      },
      icon: const Icon(Icons.close),
      iconAlignment: .end,
      label: Text(
        context.l10n.disassemble,
        style: TextStyle(
          color: context.newThemeData.textTheme.titleSmall!.color,
        ),
      ),
    );
  }
}
