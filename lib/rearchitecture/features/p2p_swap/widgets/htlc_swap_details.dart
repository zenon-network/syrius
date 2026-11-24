import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/details_row.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays expandable technical details for an HTLC swap.
class HtlcSwapDetailsWidget extends StatefulWidget {
  /// Creates a details widget for the provided swap.
  const HtlcSwapDetailsWidget({
    required this._swap,
    super.key,
  });

  final HtlcSwap _swap;

  @override
  State<HtlcSwapDetailsWidget> createState() => _HtlcSwapDetailsWidgetState();
}

class _HtlcSwapDetailsWidgetState extends State<HtlcSwapDetailsWidget> {
  final Duration _animationDuration = const Duration(milliseconds: 100);

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextButton.icon(
          iconAlignment: IconAlignment.end,
          icon: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: _animationDuration,
            child: const Icon(Icons.keyboard_arrow_down),
          ),
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          label: Text(
            _isExpanded ? context.l10n.hideDetails : context.l10n.showDetails,
          ),
        ),
        AnimatedSwitcher(
          duration: _animationDuration,
          transitionBuilder:
              (
                Widget child,
                Animation<double> animation,
              ) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: child,
                );
              },
          child: _isExpanded
              ? Column(
                  children: <Widget>[
                    kVerticalGap16,
                    Divider(
                      color: Colors.white.withAlpha((255 * 0.1).round()),
                    ),
                    kVerticalGap16,
                    _buildDetailsList(widget._swap),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildDetailsList(HtlcSwap swap) {
    final String yourDepositId = swap.direction == P2pSwapDirection.outgoing
        ? swap.initialHtlcId
        : swap.counterHtlcId!;
    final String? counterpartyDepositId =
        swap.direction == P2pSwapDirection.incoming
        ? swap.initialHtlcId
        : swap.counterHtlcId;

    final List<Widget> children = <Widget>[
      DetailsRow(
        label: context.l10n.yourAddress,
        value: swap.selfAddress,
        valueToShow: ZenonAddressUtils.getLabel(swap.selfAddress),
      ),
      DetailsRow(
        label: context.l10n.counterpartyAddress,
        value: swap.counterpartyAddress,
        valueToShow: ZenonAddressUtils.getLabel(swap.counterpartyAddress),
      ),
      DetailsRow(
        label: context.l10n.yourDepositId,
        value: yourDepositId,
        valueToShow: Hash.parse(yourDepositId).toShortString(),
      ),
      DetailsRow(
        label: context.l10n.hashlock,
        value: swap.hashLock,
        valueToShow: Hash.parse(swap.hashLock).toShortString(),
      ),
    ];

    if (counterpartyDepositId != null) {
      children.add(
        DetailsRow(
          label: context.l10n.counterpartyDepositId,
          value: counterpartyDepositId,
          valueToShow: Hash.parse(counterpartyDepositId).toShortString(),
        ),
      );
    }
    if (swap.preimage != null) {
      children.add(
        DetailsRow(
          label: context.l10n.swapSecret,
          value: swap.preimage!,
          valueToShow: Hash.parse(swap.preimage!).toShortString(),
        ),
      );
    }

    return Column(
      spacing: kVerticalGap16.height!,
      children: children,
    );
  }
}
