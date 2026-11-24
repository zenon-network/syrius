import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pow_generating_status_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card with the actions available for native P2P swaps.
class P2pSwapOptionsCard extends StatelessWidget {
  /// Creates a P2P swap options card.
  const P2pSwapOptionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StartP2pSwapBloc>(
      create: (_) => StartP2pSwapBloc(
        accountBlockUtils: AccountBlockUtils(
          publishSuccessNotification: false,
        ),
        swapRepository: sl<HtlcSwapRepository>(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        body: const _View(),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.options,
    description: context.l10n.p2pSwapOptionsDescription,
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return BlocListener<StartP2pSwapBloc, StartP2pSwapState>(
      listener: _onStartP2pSwapStateChanged,
      child: StreamBuilder<PowStatus>(
        stream: sl.get<PowGeneratingStatusBloc>().stream,
        builder: (_, AsyncSnapshot<PowStatus> snapshot) {
          if (snapshot.hasError) {
            return SyriusErrorWidget(snapshot.error!);
          }

          return _buildNativeOptions(
            context: context,
            isGeneratingPlasma: snapshot.data == PowStatus.generating,
          );
        },
      ),
    );
  }

  Widget _buildNativeOptions({
    required BuildContext context,
    required bool isGeneratingPlasma,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        P2pSwapOptionsButton(
          title: context.l10n.p2pSwapStart,
          subtitle: context.l10n.p2pSwapStartDescription,
          onClick: () => isGeneratingPlasma
              ? _showGeneratingPlasmaToast(context)
              : unawaited(_onStartSwapPressed(context)),
        ),
        kVerticalGap25,
        P2pSwapOptionsButton(
          title: context.l10n.joinSwap,
          subtitle: context.l10n.p2pSwapJoinDescription,
          onClick: () => isGeneratingPlasma
              ? _showGeneratingPlasmaToast(context)
              : unawaited(_onJoinSwapPressed(context)),
        ),
        kVerticalGap25,
        const Center(
          child: ViewSwapTutorialButton(),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => showCustomDialog(
              context: context,
              content: const ReclaimDepositModal(),
            ),
            label: Text(context.l10n.reclaimDeposit),
            icon: const Icon(Icons.refresh),
            iconAlignment: IconAlignment.end,
          ),
        ),
      ],
    );
  }

  Future<void> _onStartSwapPressed(BuildContext context) async {
    final bool canContinue = await _confirmUserWarningIfNeeded(context);

    if (!canContinue || !context.mounted) {
      return;
    }

    unawaited(
      showCustomDialog(
        context: context,
        content: BlocProvider<StartP2pSwapBloc>.value(
          value: context.read<StartP2pSwapBloc>(),
          child: const StartP2pSwapModal(),
        ),
      ),
    );
  }

  Future<void> _onJoinSwapPressed(BuildContext context) async {
    final bool canContinue = await _confirmUserWarningIfNeeded(context);

    if (!canContinue || !context.mounted) {
      return;
    }

    final String? swapId = await showCustomDialog<String>(
      context: context,
      content: const JoinP2pSwapModal(),
    );

    if (swapId == null || !context.mounted) {
      return;
    }

    _showNativeSwapDetailsModal(context, swapId);
    unawaited(
      NotificationUtils.showForegroundNotification(
        context,
        WalletNotification(
          title: context.l10n.swapJoined,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: context.l10n.hashValue(swapId),
          type: NotificationType.paymentSent,
        ),
      ),
    );
  }

  Future<bool> _confirmUserWarningIfNeeded(BuildContext context) async {
    final bool hasReadWarning = sharedPrefsService!.get(
      kHasReadP2pSwapWarningKey,
      defaultValue: kHasReadP2pSwapWarningDefaultValue,
    );

    if (hasReadWarning) {
      return true;
    }

    final bool? result = await showCustomDialog<bool>(
      context: context,
      content: const P2pSwapWarningModal(),
    );

    if (result == true) {
      await sharedPrefsService!.put(kHasReadP2pSwapWarningKey, true);
      return true;
    }

    return false;
  }

  void _showNativeSwapDetailsModal(BuildContext context, String swapId) {
    unawaited(
      showCustomDialog(
        context: context,
        content: P2pSwapModal(
          swapId: swapId,
        ),
      ),
    );
  }

  void _onStartP2pSwapStateChanged(
    BuildContext context,
    StartP2pSwapState state,
  ) {
    if (state is StartP2pSwapDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _showNativeSwapDetailsModal(context, state.swap.id);
          unawaited(
            NotificationUtils.showForegroundNotification(
              context,
              WalletNotification(
                title: context.l10n.swapStarted,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details: context.l10n.hashValue(state.swap.initialHtlcId),
                type: NotificationType.paymentSent,
              ),
            ),
          );
        }
      });
    } else if (state case StartP2pSwapFailure(
      :final SyriusException exception,
    )) {
      unawaited(
        NotificationUtils.showForegroundError(
          context,
          exception,
          context.l10n.errorStartingSwap,
        ),
      );
    }
  }

  void _showGeneratingPlasmaToast(BuildContext context) {
    ToastUtils.showToast(context, context.l10n.p2pSwapGeneratingPlasma);
  }
}
