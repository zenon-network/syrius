import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class CreateToken extends StatefulWidget {

  const CreateToken({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State createState() {
    return _CreateTokenState();
  }
}

class _CreateTokenState extends State<CreateToken> {
  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Create Token',
      description: 'Create a token following the ZTS specification',
      childBuilder: _getWidgetBody,
    );
  }

  Widget _getWidgetBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/lottie/ic_anim_zts.json',
          width: 128,
          height: 128,
          repeat: false,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
          child: SyriusElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StepperScreen(
                    stepper: const TokenStepper(),
                    onStepperNotificationSeeMorePressed:
                        widget.onStepperNotificationSeeMorePressed,
                  ),
                ),
              );
            },
            text: 'Create Token',
            initialFillColor: AppColors.znnColor,
            icon: _getFilledButtonIcon(),
          ),
        ),
      ],
    );
  }

  Widget _getFilledButtonIcon() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.znnColor,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 15,
      ),
    );
  }
}
