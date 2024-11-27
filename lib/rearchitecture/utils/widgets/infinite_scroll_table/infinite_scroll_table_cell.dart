part of 'infinite_scroll_table.dart';

class InfiniteScrollTableCell extends StatelessWidget {
  const InfiniteScrollTableCell({
    required this.child,
    this.flex = 1,
    super.key,
  });

  factory InfiniteScrollTableCell.withText({
    required BuildContext context,
    required String content,
    String? textToBeCopied,
    TextStyle? textStyle,
    int flex = 1,
    String tooltipMessage = '',
  }) =>
      InfiniteScrollTableCell(
        flex: flex,
        child: Row(
          children: <Widget>[
            Flexible(
              child: Tooltip(
                message: tooltipMessage,
                child: Text(
                  content,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: textStyle ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.subtitleColor,
                          ),
                ),
              ),
            ),
            if (textToBeCopied != null)
              Row(
                children: <Widget>[
                  CopyToClipboardButton(
                    textToBeCopied,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
          ],
        ),
      );

  factory InfiniteScrollTableCell.textFromAddress({
    required Address address,
    required BuildContext context,
    bool checkIfStakeAddress = false,
    bool isShortVersion = true,
  }) {
    final TextStyle? textStyle = address.isEmbedded() ||
            (checkIfStakeAddress && address.toString() == kSelectedAddress)
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.znnColor,
              fontWeight: FontWeight.bold,
            )
        : null;

    final bool hasLabel = kAddressLabelMap[address.toString()] != null;

    final String content = hasLabel
        ? ZenonAddressUtils.getLabel(address.toString())
        : isShortVersion
            ? address.toShortString()
            : address.toString();

    return InfiniteScrollTableCell.withText(
      content: content,
      context: context,
      flex: 2,
      textStyle: textStyle,
      tooltipMessage: address.toString(),
      textToBeCopied: address.toString(),
    );
  }

  final Widget child;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      fit: FlexFit.tight,
      child: child,
    );
  }
}
