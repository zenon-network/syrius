import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/notification_widget.dart';

class StepperScreen extends StatelessWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;
  final Widget stepper;

  const StepperScreen({
    required this.stepper,
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NotificationWidget(
              onSeeMorePressed: onStepperNotificationSeeMorePressed,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(
                    15.0,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    stepper,
                    Positioned(
                      top: 0.0,
                      right: 0.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          RawMaterialButton(
                            constraints: const BoxConstraints.tightForFinite(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.all(20.0),
                            shape: const CircleBorder(),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(
                              Icons.clear,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
