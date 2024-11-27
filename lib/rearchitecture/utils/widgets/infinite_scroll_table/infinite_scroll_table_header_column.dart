part of 'infinite_scroll_table.dart';

/// A widget that represents a column inside the [InfiniteScrollTable] header.
///
/// Currently the sort arrows are not visible, by default, so the row sorting
/// is disabled
class InfiniteScrollTableHeaderColumn extends StatelessWidget {
  /// Creates a new instance.
  const InfiniteScrollTableHeaderColumn({
    required this.columnName,
    this.onSortArrowsPressed,
    this.contentAlign = MainAxisAlignment.start,
    this.flex = 1,
    super.key,
  });
  /// The name of the column.
  final String columnName;
  /// Callback to be executed when the sort arrows are pressed.
  final Function(String)? onSortArrowsPressed;
  /// Defines how to align the column name.
  final MainAxisAlignment contentAlign;
  /// Defines how much space the column should take.
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: contentAlign,
        children: <Widget>[
          Expanded(
            child: Text(
              columnName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          // TODO(community): enable row sorting
          Visibility(
            visible: false,
            child: InkWell(
              onTap: () => onSortArrowsPressed!(columnName),
              child: Icon(
                Icons.sort,
                size: 15,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
