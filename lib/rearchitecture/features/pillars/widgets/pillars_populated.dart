import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A widget associated with the [PillarsState] when it's status is
/// [TimerStatus.success] that displays the number of pillars
class PillarsPopulated extends StatelessWidget {
  /// Creates a PillarsPopulated object
  const PillarsPopulated({required this.numberOfPillars, super.key});
  /// Number of pillars in the network
  final int numberOfPillars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SvgPicture.asset(
          'assets/svg/ic_pillars_dashboard.svg',
          width: 65,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: numberOfPillars,
              isInt: true,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Active Pillars',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
