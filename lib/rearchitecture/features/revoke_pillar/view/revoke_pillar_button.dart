import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/revoke_pillar/bloc/revoke_pillar_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Button that handles the pillar revoke/disassemble flow.
class RevokePillarButton extends StatelessWidget {
  /// Creates a [RevokePillarButton].
  const RevokePillarButton({
    required this.pillarName,
    required this.onRevoked,
    super.key,
  });

  /// Name of the pillar to revoke.
  final String pillarName;

  /// Called after the pillar revoke operation succeeds.
  final VoidCallback onRevoked;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RevokePillarBloc>(
      create: (_) => RevokePillarBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: BlocConsumer<RevokePillarBloc, RevokePillarState>(
        listener: (BuildContext context, RevokePillarState state) {
          if (state is RevokePillarDone) {
            onRevoked();
          } else if (state is RevokePillarFailure) {
            unawaited(
              NotificationUtils.sendNotificationError(
                state.exception,
                context.l10n.errorDisassemblingPillar,
              ),
            );
          }
        },
        builder: (BuildContext context, RevokePillarState state) {
          return switch (state) {
            RevokePillarLoading() => const SyriusLoadingWidget(size: 25),
            _ => _buildButton(context),
          };
        },
      ),
    );
  }

  OutlinedButton _buildButton(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        iconColor: AppColors.errorColor,
        side: const BorderSide(
          color: AppColors.errorColor,
        ),
      ),
      onPressed: () async {
        final RevokePillarBloc revokePillarBloc = context
            .read<RevokePillarBloc>();
        final bool? revocationConfirmed = await showDialogWithNoAndYesOptions(
          isBarrierDismissible: false,
          context: context,
          title: context.l10n.disassemble,
          // TODO(maznnwell): localize if the description is okay
          description: 'Are you sure you want to revoke the pillar?',
        );

        if (revocationConfirmed ?? false) {
          revokePillarBloc.add(
            RevokePillarRequested(pillarName: pillarName),
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
