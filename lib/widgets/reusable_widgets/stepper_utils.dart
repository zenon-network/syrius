import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StepperUtils {
  static custom_material_stepper.Step getMaterialStep({
    required String stepTitle,
    required Widget stepContent,
    required String stepSubtitle,
    required custom_material_stepper.StepState stepState,
    required BuildContext context,
    bool expanded = false,
    Color stepSubtitleColor = AppColors.znnColor,
    IconData? stepSubtitleIconData,
  }) {
    return custom_material_stepper.Step(
      title: Text(
        stepTitle,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      subtitle: stepState == custom_material_stepper.StepState.complete
          ? Row(
              children: [
                Text(
                  stepSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 12.0,
                        color: stepSubtitleColor,
                      ),
                ),
                if (stepSubtitleIconData != null)
                  Icon(
                    stepSubtitleIconData,
                    size: 15.0,
                    color: stepSubtitleColor,
                  ),
              ],
            )
          : null,
      content: Container(
        margin: const EdgeInsets.only(left: 37.0),
        child: Row(
          children: [
            Expanded(
              child: stepContent,
            ),
            if (!expanded)
              Expanded(
                child: Container(),
              ),
          ],
        ),
      ),
      state: stepState,
    );
  }

  static custom_material_stepper.StepState getStepState(
      int currentStepIndex, int? completedStepIndex) {
    return currentStepIndex <= (completedStepIndex ?? -1)
        ? custom_material_stepper.StepState.complete
        : custom_material_stepper.StepState.indexed;
  }

  static Widget getBalanceWidget(Token token, AccountInfo accountInfo) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 10.0),
          child: AvailableBalance(
            token,
            accountInfo,
          ),
        ),
      ],
    );
  }
}
