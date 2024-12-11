import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pow_generating_status_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/join_native_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/native_p2p_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/p2p_swap_warning_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/recover_deposit_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/start_native_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swap_options_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class P2pSwapOptionsCard extends StatefulWidget {
  const P2pSwapOptionsCard({
    super.key,
  });

  @override
  State<P2pSwapOptionsCard> createState() => _P2pSwapOptionsCardState();
}

class _P2pSwapOptionsCardState extends State<P2pSwapOptionsCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'P2P Swap Options',
      description: 'Starting and joining P2P swaps can be done from this card.',
      childBuilder: () => _getWidgetBody(context),
      customItem: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            showCustomDialog(
              context: context,
              content: const RecoverDepositModal(),
            );
          },
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.refresh,
                color: AppColors.znnColor,
                size: 20,
              ),
              const SizedBox(
                width: 5,
                height: 38,
              ),
              Expanded(
                child: Text(
                  'Recover deposit',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return StreamBuilder<PowStatus>(
      stream: sl.get<PowGeneratingStatusBloc>().stream,
      builder: (_, AsyncSnapshot<PowStatus> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        final bool isGeneratingPlasma = _isGeneratingPlasma(snapshot.data);
        return Container(
          margin: const EdgeInsets.all(20),
          child: _getNativeOptions(isGeneratingPlasma),
        );
      },
    );
  }

  void _showUserWarningModalIfNeeded({required VoidCallback onContinue}) {
    final hasReadWarning = sharedPrefsService!.get(
      kHasReadP2pSwapWarningKey,
      defaultValue: kHasReadP2pSwapWarningDefaultValue,
    );
    if (hasReadWarning == false) {
      showCustomDialog(
        context: context,
        content: P2PSwapWarningModal(onAccepted: () {
          Navigator.pop(context);
          sharedPrefsService!.put(kHasReadP2pSwapWarningKey, true);
          Timer.run(onContinue);
        },),
      );
    } else {
      onContinue();
    }
  }

  void _showNativeSwapModal(String swapId) {
    Navigator.pop(context);
    Timer.run(
      () => showCustomDialog(
        context: context,
        content: NativeP2pSwapModal(
          swapId: swapId,
        ),
      ),
    );
  }

  Column _getNativeOptions(bool isGeneratingPlasma) {
    return Column(
      children: <Widget>[
        P2pSwapOptionsButton(
          primaryText: 'Start swap',
          secondaryText: 'Start a native swap with a counterparty.',
          onClick: () => isGeneratingPlasma
              ? _showGeneratingPlasmaToast()
              : _showUserWarningModalIfNeeded(
                  onContinue: () => showCustomDialog(
                        context: context,
                        content: StartNativeSwapModal(
                            onSwapStarted: _showNativeSwapModal,),
                      ),),
        ),
        const SizedBox(
          height: 25,
        ),
        P2pSwapOptionsButton(
          primaryText: 'Join swap',
          secondaryText: 'Join a native swap started by a counterparty.',
          onClick: () => isGeneratingPlasma
              ? _showGeneratingPlasmaToast()
              : _showUserWarningModalIfNeeded(
                  onContinue: () => showCustomDialog(
                    context: context,
                    content:
                        JoinNativeSwapModal(onJoinedSwap: _showNativeSwapModal),
                  ),
                ),
        ),
        const SizedBox(
          height: 40,
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'View swap tutorial',
                  style: TextStyle(
                    color: AppColors.subtitleColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(
                  width: 3,
                ),
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: AppColors.subtitleColor,
                ),
              ],
            ),
            onTap: () => NavigationUtils.openUrl(kP2pSwapTutorialLink),
          ),
        ),
        const SizedBox(
          height: 40,
        ),
      ],
    );
  }

  bool _isGeneratingPlasma(PowStatus? status) {
    return status != null && status == PowStatus.generating;
  }

  void _showGeneratingPlasmaToast() {
    ToastUtils.showToast(context, 'Please wait while Plasma is generated');
  }
}
