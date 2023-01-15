import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class DynamicMultiplierRewardsCard extends StatelessWidget {
  const DynamicMultiplierRewardsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Dynamic Multiplier Rewards',
      description:
          'The dynamic multiplier is active until the 1.8M QSR liquidity fund is fully distributed',
      childBuilder: () => _getCardBody(context),
    );
  }

  Widget _getCardBody(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15.0,
          ),
          child: Row(
            children: List.generate(
              kLiquidityRewardsMultiplier,
              (index) => _getMultiplier(
                index + 1,
                context,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 15.0,
          ),
          child: DottedBorderInfoWidget(
            text:
                'Up to 10x daily QSR rewards until the 1.8M QSR liquidity fund is fully distributed',
            borderColor: AppColors.qsrColor,
          ),
        ),
      ],
    );
  }

  Widget _getMultiplier(int multiplier, BuildContext context) {
    Color fillColor = AppColors.qsrColor
        .withOpacity(multiplier / kLiquidityRewardsMultiplier);

    return Expanded(
      flex: (multiplier + kLiquidityRewardsMultiplier) ~/ 2,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${multiplier * 1000}',
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        fontSize: 7.0,
                      ),
                ),
                SizedBox(
                  height: kVerticalSpacing.height! / 2,
                ),
                Container(
                  width: 3.0,
                  height: 3.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fillColor,
                  ),
                ),
                SizedBox(
                  height: kVerticalSpacing.height! / 2,
                ),
                Container(
                  height: 10.0,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                kVerticalSpacing,
                Text(
                  '${multiplier}x',
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        fontSize: 7.0,
                      ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: multiplier < kLiquidityRewardsMultiplier,
            child: const SizedBox(
              width: 5.0,
            ),
          ),
        ],
      ),
    );
  }
}
