import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [TotalHourlyTransactionsState] when it's
/// status is [TimerStatus.success] that displays the number of transactions
/// confirmed in the last one hour
class TotalHourlyTransactionsPopulated extends StatelessWidget {
  /// Creates a TotalHourlyTransactionsPopulated object.
  const TotalHourlyTransactionsPopulated({required this.count, super.key});
  /// The number of confirmed transactions in the last one hour
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        NumberAnimation(
          end: count,
          isInt: true,
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            fontSize: 30,
          ),
        ),
        kVerticalSpacing,
        Text(context.l10n.transactionsLastHour),
      ],
    );
  }
}
