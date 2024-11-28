import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class DateColumn extends StatelessWidget {
  const DateColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTableHeaderColumn(
      columnName: context.l10n.date,
    );
  }
}
