import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class StepperScreen extends StatelessWidget {
  const StepperScreen({
    required this.stepper,
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });

  final VoidCallback onStepperNotificationSeeMorePressed;
  final Widget stepper;

  @override
  Widget build(BuildContext context) {
    //TODO: to delete Theme widget once only the new theme is being used
    return Theme(
      data: context.newThemeData,
      child: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              NotificationWidget(
                onSeeMorePressed: onStepperNotificationSeeMorePressed,
              ),
              Expanded(
                child: Card(
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      stepper,
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
