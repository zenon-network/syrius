import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class P2pSwapsListItem extends StatefulWidget {

  const P2pSwapsListItem({
    required this.swap,
    required this.onTap,
    required this.onDelete,
    super.key,
  });
  final P2pSwap swap;
  final Function(String) onTap;
  final Function(P2pSwap) onDelete;

  @override
  State<P2pSwapsListItem> createState() => _P2pSwapsListItemState();
}

class _P2pSwapsListItemState extends State<P2pSwapsListItem> {
  bool _isDeleteIconHovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      elevation: 1,
      borderRadius: BorderRadius.circular(
        8,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onTap.call(widget.swap.id),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 20,
                child: Row(
                  children: <Widget>[
                    _getStatusWidget(),
                    const SizedBox(
                      width: 8,
                    ),
                    _getStatusText(),
                  ],
                ),
              ),
              Expanded(
                flex: 20,
                child: _getAmountWidget(
                    widget.swap.fromAmount,
                    widget.swap.fromDecimals,
                    widget.swap.fromTokenStandard,
                    widget.swap.fromSymbol,),
              ),
              Expanded(
                flex: 20,
                child: widget.swap.state == P2pSwapState.completed
                    ? _getAmountWidget(
                        widget.swap.toAmount,
                        widget.swap.toDecimals,
                        widget.swap.toTokenStandard,
                        widget.swap.toSymbol,)
                    : _getTextWidget('-'),
              ),
              Expanded(
                flex: 20,
                child: _getTextWidget(
                  _formatTime(widget.swap.startTime * 1000),
                ),
              ),
              Expanded(
                flex: 20,
                child: _getActionButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getStatusWidget() {
    const double size = 16;
    switch (widget.swap.state) {
      case P2pSwapState.pending:
      case P2pSwapState.active:
        return const SyriusLoadingWidget(
          size: 12,
          strokeWidth: 2,
          padding: 2,
        );
      case P2pSwapState.completed:
        return const Icon(Icons.check_circle_outline,
            color: AppColors.znnColor, size: size,);
      default:
        return const Icon(Icons.cancel_outlined,
            color: AppColors.errorColor, size: size,);
    }
  }

  Widget _getStatusText() {
    late final String text;
    switch (widget.swap.state) {
      case P2pSwapState.pending:
        text = 'Starting';
      case P2pSwapState.active:
        text = 'Active';
      case P2pSwapState.completed:
        text = 'Completed';
      default:
        text = 'Unsuccessful';
    }
    return _getTextWidget(text);
  }

  Widget _getTextWidget(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12, height: 1, color: AppColors.subtitleColor,),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,);
  }

  Widget _getAmountWidget(
      BigInt? amount, int? decimals, String? tokenStandard, String? symbol,) {
    if (amount == null ||
        decimals == null ||
        tokenStandard == null ||
        symbol == null) {
      return _getTextWidget('-');
    }
    return Row(
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              constraints: const BoxConstraints(maxWidth: 70),
              child: _getTextWidget(amount.addDecimals(decimals)),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 50),
              child: _getTextWidget(' $symbol'),
            ),
          ],
        ),
        const SizedBox(
          width: 6,
        ),
        Container(
          height: 6,
          width: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorUtils.getTokenColor(
              TokenStandard.parse(tokenStandard),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getActionButton() {
    switch (widget.swap.state) {
      case P2pSwapState.completed:
      case P2pSwapState.unsuccessful:
        return Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  4,
                ),
                color: const Color(0xff333333),
              ),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _isDeleteIconHovered = true),
                onExit: (_) => setState(() => _isDeleteIconHovered = false),
                child: GestureDetector(
                  onTap: () => widget.onDelete.call(widget.swap),
                  child: Icon(
                    Icons.delete,
                    color: _isDeleteIconHovered
                        ? Colors.white
                        : AppColors.subtitleColor,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        );
      case P2pSwapState.reclaimable:
        return Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () => widget.onTap.call(widget.swap.id),
                child: const Text(
                  'Reclaim funds',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      default:
        return Container();
    }
  }

  String _formatTime(int transactionMillis) {
    final int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (currentMillis - transactionMillis <=
        const Duration(days: 1).inMilliseconds) {
      return _formatTimeShort(currentMillis - transactionMillis);
    }
    return FormatUtils.formatDate(transactionMillis,
        dateFormat: 'MM/dd/yyyy hh:mm a',);
  }

  String _formatTimeShort(int i) {
    final Duration duration = Duration(milliseconds: i);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ago';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min ago';
    }
    return '${duration.inSeconds} s ago';
  }
}
