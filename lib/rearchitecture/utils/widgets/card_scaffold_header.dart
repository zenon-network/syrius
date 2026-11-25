import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/refresh_button/view/view.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/constants.dart';

/// A widget showing a [title] along with some icon buttons
class CardScaffoldHeader extends StatelessWidget {
  /// Creates a new instance.
  const CardScaffoldHeader({
    required this.onMoreIconPressed,
    required this.onRefreshPressed,
    required this.title,
    this.isRefreshLoading,
    this.actions = const <Widget>[],
    super.key,
  });

  /// Title that will appear in the header.
  final String title;

  /// Callback triggered when the more icon is pressed.
  final VoidCallback onMoreIconPressed;

  /// Optional callback that can be trigger from the refresh icon.
  final VoidCallback? onRefreshPressed;

  /// Optional listenable controlling whether the refresh icon shows a loading
  /// indicator while a refresh is in flight.
  final ValueListenable<bool>? isRefreshLoading;

  /// Optional trailing action widgets shown before the refresh and more icons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                kHorizontalGap4,
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            ...actions,
            if (onRefreshPressed != null)
              RefreshButton(
                onPressed: onRefreshPressed!,
                isLoadingListenable: isRefreshLoading,
              ),
            IconButton(
              mouseCursor: SystemMouseCursors.click,
              icon: const Icon(Icons.more_horiz),
              onPressed: onMoreIconPressed,
            ),
          ],
        ),
      ],
    );
  }
}
