part of 'infinite_scroll_table.dart';

/// A cell in a table
///
/// It's based on the [Expanded] widgets, so the [child] will be forced to
/// occupy the entire available space. The space in the row is determined by
/// the [flex].
class InfiniteScrollTableCell extends StatelessWidget {
  /// Creates a new instance.
  const InfiniteScrollTableCell({
    required this.child,
    this.flex = 1,
    super.key,
  });

  /// A constructor used when the main child widget is a [Text].
  ///
  /// If [tooltipMessage] is not empty, then a tooltip message will appear
  /// If [textToBeCopied] is not null, then the cell will also have a
  /// [CopyToClipboardButton] widget that copies to clipboard the
  /// [textToBeCopied] - which is not already the same as the [content] value.
  factory InfiniteScrollTableCell.withText({
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
                  style: textStyle,
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

  /// A constructor that helps creating cell content starting from an [address].
  ///
  /// Useful especially for styling cell content when the address is one of the
  /// user's wallet
  factory InfiniteScrollTableCell.textFromAddress({
    required Address address,
    bool isStakeAddress = false,
    bool isShortVersion = true,
  }) {
    final TextStyle? textStyle = address.isEmbedded() ||
            (isStakeAddress && address.toString() == kSelectedAddress)
        ? const TextStyle(
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
      flex: 2,
      textStyle: textStyle,
      tooltipMessage: address.toString(),
      textToBeCopied: address.toString(),
    );
  }

  /// The child that represents the content of the cell
  final Widget child;
  /// Represents the space amount in a row assign to the cell
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: child,
    );
  }
}
