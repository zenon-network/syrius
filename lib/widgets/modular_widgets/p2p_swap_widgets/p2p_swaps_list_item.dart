import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class P2pSwapsListItem extends StatefulWidget {
  final P2pSwap swap;
  final Function(String) onTap;
  final Function(P2pSwap) onDelete;

  const P2pSwapsListItem({
    required this.swap,
    required this.onTap,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  State<P2pSwapsListItem> createState() => _P2pSwapsListItemState();
}

class _P2pSwapsListItemState extends State<P2pSwapsListItem> {
  bool _isDeleteIconHovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      elevation: 1.0,
      borderRadius: BorderRadius.circular(
        8.0,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onTap.call(widget.swap.id),
        child: Container(
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                flex: 20,
                child: Row(
                  children: [
                    _getStatusWidget(),
                    const SizedBox(
                      width: 8.0,
                    ),
                    _getStatusText()
                  ],
                ),
              ),
              Expanded(
                flex: 20,
                child: _getAmountWidget(
                    widget.swap.fromAmount,
                    widget.swap.fromDecimals,
                    widget.swap.fromTokenStandard,
                    widget.swap.fromSymbol),
              ),
              Expanded(
                flex: 20,
                child: widget.swap.state == P2pSwapState.completed
                    ? _getAmountWidget(
                        widget.swap.toAmount,
                        widget.swap.toDecimals,
                        widget.swap.toTokenStandard,
                        widget.swap.toSymbol)
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
    const size = 16.0;
    switch (widget.swap.state) {
      case P2pSwapState.pending:
      case P2pSwapState.active:
        return const SyriusLoadingWidget(
          size: 12.0,
          strokeWidth: 2.0,
          padding: 2.0,
        );
      case P2pSwapState.completed:
        return const Icon(Icons.check_circle_outline,
            color: AppColors.znnColor, size: size);
      default:
        return const Icon(Icons.cancel_outlined,
            color: AppColors.errorColor, size: size);
    }
  }

  Widget _getStatusText() {
    late final String text;
    switch (widget.swap.state) {
      case P2pSwapState.pending:
        text = 'Starting';
        break;
      case P2pSwapState.active:
        text = 'Active';
        break;
      case P2pSwapState.completed:
        text = 'Completed';
        break;
      default:
        text = 'Unsuccessful';
    }
    return _getTextWidget(text);
  }

  Widget _getTextWidget(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 12.0, height: 1, color: AppColors.subtitleColor),
    );
  }

  Widget _getAmountWidget(
      int? amount, int? decimals, String? tokenStandard, String? symbol) {
    if (amount == null ||
        decimals == null ||
        tokenStandard == null ||
        symbol == null) {
      return _getTextWidget('-');
    }
    return Row(
      children: [
        _getTextWidget('${amount.addDecimals(decimals)} $symbol'),
        const SizedBox(
          width: 6.0,
        ),
        Container(
          height: 6.0,
          width: 6.0,
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
                  4.0,
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
                    size: 18.0,
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
              height: 32.0,
              child: ElevatedButton(
                onPressed: () => widget.onTap.call(widget.swap.id),
                child: const Text(
                  'Reclaim funds',
                  style: TextStyle(fontSize: 12.0, color: Colors.white),
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
    int currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (currentMillis - transactionMillis <=
        const Duration(days: 1).inMilliseconds) {
      return _formatTimeShort(currentMillis - transactionMillis);
    }
    return FormatUtils.formatDate(transactionMillis,
        dateFormat: 'MM/dd/yyyy hh:mm a');
  }

  String _formatTimeShort(int i) {
    Duration duration = Duration(milliseconds: i);
    if (duration.inHours > 0) {
      return '${duration.inHours} h ago';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min ago';
    }
    return '${duration.inSeconds} s ago';
  }
}
