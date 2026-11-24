import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Reclaimable native P2P swap content.
class ReclaimableSwapView extends StatelessWidget {
  /// Creates a [ReclaimableSwapView].
  const ReclaimableSwapView({required this._swap, super.key});

  final HtlcSwap _swap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReclaimDepositBloc>(
      create: (_) => ReclaimDepositBloc(
        accountBlockUtils: AccountBlockUtils(
          publishSuccessNotification: false,
        ),
        walletAddresses: kDefaultAddressList.whereType<String>().toSet(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: _View(swap: _swap),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this._swap});

  final HtlcSwap _swap;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  @override
  Widget build(BuildContext context) {
    final ({int expirationTime, String id}) fundedHtlc =
        widget._swap.fundedHtlc!;
    final Duration remainingDuration = Duration(
      seconds: fundedHtlc.expirationTime - DateTime.now().unixTimestamp,
    );
    final bool canReclaim = remainingDuration.inSeconds <= 0;

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
          canReclaim
              ? context.l10n.swapUnsuccessful
              : context.l10n.swapUnsuccessfulWaitForExpiration,
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
                Text(context.l10n.depositedAmount),
                SwapAmountInfo(
                  amount: widget._swap.fromAmount,
                  token: widget._swap.fromToken,
                ),
              ],
            ),
          ),
        ),
        if (remainingDuration.inSeconds > 0)
          TweenAnimationBuilder<Duration>(
            duration: remainingDuration,
            tween: .new(begin: remainingDuration, end: Duration.zero),
            onEnd: () => setState(() {}),
            builder: (_, Duration duration, _) {
              return Visibility(
                visible: duration.inSeconds > 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(context.l10n.depositExpiresIn),
                      Text(duration.toString().split('.').first),
                    ],
                  ),
                ),
              );
            },
          ),
        if (canReclaim)
          ReclaimDepositButton(
            depositId: fundedHtlc.id,
            isEnabled: true,
            text: context.l10n.reclaimDeposit,
            loadingText: context.l10n.reclaimingFundsPleaseWait,
            successMessage: context.l10n.swapReclaimBlockCreated,
          ),
        HtlcSwapDetailsWidget(swap: widget._swap),
      ],
    );
  }
}
