import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/screens/stepper_screen.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/token_widgets/token_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/elevated_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';

class CreateToken extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const CreateToken({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

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
      childBuilder: () => _getWidgetBody(),
    );
  }

  Widget _getWidgetBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/lottie/ic_anim_zts.json',
          width: 128.0,
          height: 128.0,
          repeat: false,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
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
        size: 15.0,
      ),
    );
  }
}
