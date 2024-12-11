import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/htlc_swap.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/p2p_swap_widgets/detail_row.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class HtlcSwapDetailsWidget extends StatefulWidget {

  const HtlcSwapDetailsWidget({
    required this.swap,
    super.key,
  });
  final HtlcSwap swap;

  @override
  State<HtlcSwapDetailsWidget> createState() => _HtlcSwapDetailsWidgetState();
}

class _HtlcSwapDetailsWidgetState extends State<HtlcSwapDetailsWidget>
    with SingleTickerProviderStateMixin {
  final Duration _animationDuration = const Duration(milliseconds: 100);

  late final AnimationController _animationController;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(4),
          hoverColor: Colors.transparent,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              _isExpanded
                  ? _animationController.forward()
                  : _animationController.reverse();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _isExpanded ? 'Hide details' : 'Show details',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitleColor,
                  ),
                ),
                const SizedBox(
                  width: 3,
                ),
                RotationTransition(
                  turns:
                      Tween<double>(begin: 0, end: 0.5).animate(_animationController),
                  child: const Icon(Icons.keyboard_arrow_down, size: 18),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: _animationDuration,
          curve: Curves.easeInOut,
          child: Visibility(
            visible: _isExpanded,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 20),
                _getDetailsList(widget.swap),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _getDetailsList(HtlcSwap swap) {
    final List<Widget> children = <Widget>[];
    final String yourDepositId = swap.direction == P2pSwapDirection.outgoing
        ? swap.initialHtlcId
        : swap.counterHtlcId!;
    final String? counterpartyDepositId = swap.direction == P2pSwapDirection.incoming
        ? swap.initialHtlcId
        : swap.counterHtlcId;
    children.add(
      DetailRow(
        label: 'Your address',
        value: swap.selfAddress,
        valueToShow: ZenonAddressUtils.getLabel(swap.selfAddress),
      ),
    );
    children.add(
      DetailRow(
        label: 'Counterparty address',
        value: swap.counterpartyAddress,
        valueToShow: ZenonAddressUtils.getLabel(swap.counterpartyAddress),
      ),
    );
    children.add(
      DetailRow(
        label: 'Your deposit ID',
        value: yourDepositId,
        valueToShow: Hash.parse(yourDepositId).toShortString(),
      ),
    );
    if (counterpartyDepositId != null) {
      children.add(
        DetailRow(
          label: 'Counterparty deposit ID',
          value: counterpartyDepositId,
          valueToShow: Hash.parse(counterpartyDepositId).toShortString(),
        ),
      );
    }
    children.add(
      DetailRow(
          label: 'Hashlock',
          value: swap.hashLock,
          valueToShow: Hash.parse(swap.hashLock).toShortString(),),
    );
    if (swap.preimage != null) {
      children.add(
        DetailRow(
          label: 'Swap secret',
          value: swap.preimage!,
          valueToShow: Hash.parse(swap.preimage!).toShortString(),
        ),
      );
    }

    return Column(
      children: children.zip(
        List.generate(
          children.length - 1,
          (int index) => const SizedBox(
            height: 15,
          ),
        ),
      ),
    );
  }
}
