import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// Rounded pill label displayed beneath transfer action icons.
class TransferIconLegend extends StatelessWidget {
  /// Creates a [TransferIconLegend].
  const TransferIconLegend({
    required this.legendText,
    super.key,
  });

  /// Label text displayed inside the pill.
  final String legendText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(
          10,
        ),
      ),
      child: Text(
        legendText,
        style: context.textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
