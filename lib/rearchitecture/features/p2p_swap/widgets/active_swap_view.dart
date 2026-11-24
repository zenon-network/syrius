import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/complete_swap/widgets/complete_swap_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_info_text.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Active P2P swap content.
class ActiveSwapView extends StatefulWidget {
  /// Creates an [ActiveSwapView].
  const ActiveSwapView({required this._swap, super.key});

  final HtlcSwap _swap;

  @override
  State<ActiveSwapView> createState() => _ActiveSwapViewState();
}

class _ActiveSwapViewState extends State<ActiveSwapView> {
  bool _shouldShowIncorrectAmountInstructions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: kVerticalGap16.height!,
      children: <Widget>[
        HtlcCard.sending(context: context, swap: widget._swap),
        const Icon(
          AntDesign.arrowdown,
          color: Colors.white,
        ),
        HtlcCard.receiving(context: context, swap: widget._swap),
        _buildBottomSection(widget._swap),
      ],
    );
  }

  Widget _buildBottomSection(HtlcSwap swap) {
    if (swap.counterHtlcId == null) {
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              context.l10n.shareDepositIdWithCounterparty,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge,
            ),
          ),
          kVerticalGap16,
          TextButton.icon(
            label: Text(context.l10n.copyDepositId),
            onPressed: () =>
                ClipboardUtils.copyToClipboard(swap.initialHtlcId, context),
            icon: const Icon(Icons.copy),
          ),
        ],
      );
    }

    return Column(
      spacing: kVerticalGap16.height!,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildExchangeRateWidget(swap),
        ),
        if (swap.direction == P2pSwapDirection.outgoing)
          Column(
            spacing: kVerticalGap16.height!,
            children: <Widget>[
              if (swap.toToken != null &&
                  !isTrustedToken(swap.toToken!.tokenStandard.toString()))
                Warning(
                  text: context.l10n.verifyNonFavoriteToken(
                    swap.toToken?.tokenStandard.toString() ?? '',
                  ),
                ),
              _buildExpirationWarningForOutgoingSwap(swap),
              CompleteSwapButton(swap: swap),
              _buildIncorrectAmountButton(swap),
            ],
          ),
        if (swap.direction == P2pSwapDirection.incoming)
          LoadingInfoText(
            text: context.l10n.waitingForCounterpartyKeepRunning,
            tooltipText: context.l10n.walletNotAutoLocked,
          ),
      ],
    );
  }

  Widget _buildExpirationWarningForOutgoingSwap(HtlcSwap swap) {
    const Duration warningThreshold = Duration(minutes: 10);
    final Duration timeToCompleteSwap =
        Duration(
          seconds:
              swap.counterHtlcExpirationTime! - DateTime.now().unixTimestamp,
        ) -
        kMinSafeTimeToCompleteSwap;
    return TweenAnimationBuilder<Duration>(
      duration: timeToCompleteSwap,
      tween: .new(begin: timeToCompleteSwap, end: Duration.zero),
      onEnd: () => setState(() {}),
      builder: (_, Duration duration, _) {
        return Visibility(
          visible: timeToCompleteSwap <= warningThreshold,
          child: Warning(
            text: context.l10n.swapExpiresIn(
              duration.toString().split('.').first,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncorrectAmountButton(HtlcSwap swap) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 50),
      firstCurve: Curves.easeInOut,
      firstChild: TextButton(
        onPressed: () => setState(() {
          _shouldShowIncorrectAmountInstructions = true;
        }),
        child: Text(context.l10n.receivingWrongTokenOrAmount),
      ),
      secondChild: _buildIncorrectAmountInstructions(
        swap.initialHtlcExpirationTime,
      ),
      crossFadeState: _shouldShowIncorrectAmountInstructions
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
    );
  }

  Widget _buildIncorrectAmountInstructions(int expirationTime) {
    return Text(
      context.l10n.waitToReclaimIncorrectDeposit(
        FormatUtils.formatDate(
          expirationTime * Duration.millisecondsPerSecond,
          dateFormat: kDefaultDateTimeFormat,
        ),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildExchangeRateWidget(HtlcSwap swap) {
    final BigInt? toAmount = swap.toAmount;
    final Token? toToken = swap.toToken;
    if (toAmount == null || toToken == null) {
      return const SizedBox.shrink();
    }

    return ExchangeRate(
      fromAmount: swap.fromAmount,
      fromToken: swap.fromToken,
      toAmount: toAmount,
      toToken: toToken,
    );
  }
}
