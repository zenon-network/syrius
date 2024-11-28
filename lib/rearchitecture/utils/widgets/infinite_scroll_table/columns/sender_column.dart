import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class SenderColumn extends StatelessWidget {
  const SenderColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableHeaderColumn(
      columnName: context.l10n.sender,
      flex: 2,
    );
  }
}
