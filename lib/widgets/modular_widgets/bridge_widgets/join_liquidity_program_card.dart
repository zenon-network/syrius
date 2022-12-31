import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
as custom_material_stepper;

enum JoinLiquidityProgramStep {
  joinProgram,
  addLiquidity,
}

class JoinLiquidityProgramCard extends StatefulWidget {
  const JoinLiquidityProgramCard({Key? key}) : super(key: key);

  @override
  State<JoinLiquidityProgramCard> createState() =>
      _JoinLiquidityProgramCardState();
}

class _JoinLiquidityProgramCardState extends State<JoinLiquidityProgramCard> {
  JoinLiquidityProgramStep _currentStep = JoinLiquidityProgramStep.values.first;
  JoinLiquidityProgramStep? _lastCompletedStep;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Add Liquidity',
      description: 'Become a Liquidity Provider',
      childBuilder: () => _getCardBody(context),
    );
  }

  Widget _getCardBody(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: custom_material_stepper.Stepper(
        activeColor: AppColors.qsrColor,
        currentStep: _currentStep.index,
        onStepTapped: (int index) {},
        steps: [
          StepperUtils.getMaterialStep(
            stepTitle: 'Join the Liquidity Program',
            stepContent: Row(
              children: [
                MyOutlinedButton(
                  outlineColor: AppColors.qsrColor,
                  onPressed: () => NavigationUtils.launchUrl(
                    kJoinLiquidityProgramUrl,
                    context,
                  ).then((value) => _saveProgressAndNavigateToNextStep(
                      JoinLiquidityProgramStep.joinProgram)),
                  text: 'Join',
                ),
              ],
            ),
            stepSubtitle: '',
            stepState: StepperUtils.getStepState(
              JoinLiquidityProgramStep.joinProgram.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
            expanded: true,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Add Liquidity',
            stepContent: Column(
              children: [
                Row(
                  children: [
                    MyOutlinedButton(
                      outlineColor: AppColors.qsrColor,
                      onPressed: () => NavigationUtils.launchUrl(
                        kAddLiquidityUrl,
                        context,
                      ).then((value) => _saveProgressAndNavigateToNextStep(
                          JoinLiquidityProgramStep.addLiquidity)),
                      text: 'Earn LP rewards',
                    ),
                  ],
                ),
              ],
            ),
            stepSubtitle: '',
            stepState: StepperUtils.getStepState(
              JoinLiquidityProgramStep.addLiquidity.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
            expanded: true,
          ),
        ],
      ),
    );
  }

  void _saveProgressAndNavigateToNextStep(
      JoinLiquidityProgramStep completedStep) {
    setState(() {
      _lastCompletedStep = completedStep;
      if (_lastCompletedStep!.index + 1 <
          JoinLiquidityProgramStep.values.length) {
        _currentStep =
            JoinLiquidityProgramStep.values[completedStep.index + 1];
      }
    });
  }
}
