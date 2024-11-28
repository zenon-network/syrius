import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class HashColumn extends StatelessWidget {
  const HashColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableHeaderColumn(
      columnName: context.l10n.hash,
      flex: 2,
    );
  }
}
