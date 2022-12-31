import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String _kWidgetTitle = 'Swap Decay';
const String _kWidgetDescription =
    'There will be a total of 10 Swap Cycles spanning over a period of 12 months. '
    'The Swap Decay mechanism will decrease the amount of the funds that can be '
    'swapped with each passing cycle until the swap window is closed. Starting '
    'with Swap Cycle 3, the Swap Ratio will progressively decrease each cycle '
    'by 10% until it reaches 0: after the last swap cycle is over, it won\'t '
    'be possible to swap coins from the legacy network anymore';

class SwapDecay extends StatelessWidget {
  const SwapDecay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: _kWidgetTitle,
      description: _kWidgetDescription,
      childBuilder: () => _getWidgetBody(context),
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return _getDurationUntilSwapDecayStarts().inDays > 1
        ? _showHowManyDaysLeftUntilSwapDecayStarts(context)
        : _getDurationUntilSwapDecayStarts().inSeconds > 0
            ? _showWhenSwapDecayStarts(context)
            : _getSwapDecay(context);
  }

  Widget _showHowManyDaysLeftUntilSwapDecayStarts(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NumberAnimation(
          end: _getDurationUntilSwapDecayStarts().inDays,
          isInt: true,
          style: Theme.of(context).textTheme.headline1!.copyWith(
                fontSize: 30.0,
              ),
        ),
        kVerticalSpacing,
        const Text('days until Swap Decay starts'),
      ],
    );
  }

  Duration _getDurationUntilSwapDecayStarts() {
    return DateTime.fromMillisecondsSinceEpoch(
      swapAssetDecayTimestampStart * 1000,
    ).difference(DateTime.now());
  }

  Widget _showWhenSwapDecayStarts(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'At ${FormatUtils.formatDate(
            swapAssetDecayTimestampStart * 1000,
            dateFormat: '$kDefaultDateFormat HH:mm',
          )}',
          style: Theme.of(context).textTheme.headline5,
          textAlign: TextAlign.center,
        ),
        kVerticalSpacing,
        const Text('Swap Decay will start'),
      ],
    );
  }

  _getSwapDecay(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${zenon!.embedded.swap.getSwapDecayPercentage(DateTime.now().millisecondsSinceEpoch ~/ 1000)}%',
              style: Theme.of(context).textTheme.headline1!.copyWith(
                    fontSize: 30.0,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        kVerticalSpacing,
        const Text(
          'current swap cycle decay',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
