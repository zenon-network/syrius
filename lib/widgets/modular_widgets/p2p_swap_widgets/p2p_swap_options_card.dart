import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pow_generating_status_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/toast_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/join_native_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/native_p2p_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/start_native_swap_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/modals/p2p_swap_warning_modal.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/p2p_swap_options_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class P2pSwapOptionsCard extends StatefulWidget {
  const P2pSwapOptionsCard({
    Key? key,
  }) : super(key: key);

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
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return StreamBuilder<PowStatus>(
      stream: sl.get<PowGeneratingStatusBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        final isGeneratingPlasma = _isGeneratingPlasma(snapshot.data);
        return Container(
          margin: const EdgeInsets.all(20.0),
          child: _getNativeOptions(isGeneratingPlasma),
        );
      },
    );
  }

  void _showUserWarningModalIfNeeded({required Function() onContinue}) {
    final hasReadWarning = sharedPrefsService!.get(
      kHasReadP2pSwapWarningKey,
      defaultValue: kHasReadP2pSwapWarningDefaultValue,
    );
    if (!hasReadWarning) {
      showCustomDialog(
        context: context,
        content: P2PSwapWarningModal(onAccepted: () {
          Navigator.pop(context);
          sharedPrefsService!.put(kHasReadP2pSwapWarningKey, true);
          Timer.run(onContinue);
        }),
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
      children: [
        P2pSwapOptionsButton(
          primaryText: 'Start swap',
          secondaryText: 'Start a native swap with a counterparty.',
          onClick: () => isGeneratingPlasma
              ? _showGeneratingPlasmaToast()
              : _showUserWarningModalIfNeeded(
                  onContinue: () => showCustomDialog(
                        context: context,
                        content: StartNativeSwapModal(
                            onSwapStarted: _showNativeSwapModal),
                      )),
        ),
        const SizedBox(
          height: 25.0,
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
          height: 40.0,
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'View swap tutorial',
                  style: TextStyle(
                    color: AppColors.subtitleColor,
                    fontSize: 14.0,
                  ),
                ),
                SizedBox(
                  width: 3.0,
                ),
                Icon(
                  Icons.open_in_new,
                  size: 18.0,
                  color: AppColors.subtitleColor,
                ),
              ],
            ),
            // TODO: Open link to tutorial
            onTap: () => ToastUtils.showToast(context, 'No tutorial yet'),
          ),
        ),
        const SizedBox(
          height: 40.0,
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
