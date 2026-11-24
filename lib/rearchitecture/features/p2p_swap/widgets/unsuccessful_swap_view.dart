import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Unsuccessful native P2P swap content.
class UnsuccessfulSwapView extends StatelessWidget {
  /// Creates an [UnsuccessfulSwapView].
  const UnsuccessfulSwapView({required this._swap, super.key});

  final HtlcSwap _swap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kVerticalGap16.height!,
      children: <Widget>[
        SizedBox.square(
          dimension: 70,
          child: SvgPicture.asset(
            'assets/svg/ic_unsuccessful_symbol.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.errorColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        Text(
          context.l10n.swapUnsuccessful,
          style: context.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        Card.filled(
          color: AppColors.znnColor.withAlpha((255 * 0.2).round()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(context.l10n.depositedAmountReclaimed),
                SwapAmountInfo(
                  amount: _swap.fromAmount,
                  token: _swap.fromToken,
                ),
              ],
            ),
          ),
        ),
        HtlcSwapDetailsWidget(swap: _swap),
      ],
    );
  }
}
