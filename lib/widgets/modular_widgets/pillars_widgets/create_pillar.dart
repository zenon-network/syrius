import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pillars/get_pillar_by_owner_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/screens/stepper_screen.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillars_widgets/pillar_update_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillars_widgets/pillars_stepper_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/elevated_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreatePillar extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const CreatePillar({
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  State<CreatePillar> createState() => _CreatePillarState();
}

class _CreatePillarState extends State<CreatePillar> {
  final GetPillarByOwnerBloc _getPillarByOwnerBloc = GetPillarByOwnerBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Create Pillar',
      description: 'Start the process of deploying a Pillar Node in the '
          'network',
      childBuilder: () => _getStreamBuilder(context),
    );
  }

  Widget _getStreamBuilder(BuildContext context) {
    return StreamBuilder<List<PillarInfo>>(
      stream: _getPillarByOwnerBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isNotEmpty) {
            return _getUpdatePillarWidgetBody(context, snapshot.data!.first);
          } else {
            return _getCreatePillarWidgetBody(context);
          }
        } else if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getCreatePillarWidgetBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Lottie.asset('assets/lottie/ic_anim_pillar.json', repeat: false),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SyriusElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StepperScreen(
                      stepper: const PillarsStepperContainer(),
                      onStepperNotificationSeeMorePressed:
                          widget.onStepperNotificationSeeMorePressed,
                    ),
                  ),
                );
              },
              text: 'Spawn',
              initialFillColor: AppColors.znnColor,
              icon: _getFilledButtonIcon(),
            ),
          ],
        ),
        const SizedBox(
          width: 10.0,
        ),
      ],
    );
  }

  Widget _getUpdatePillarWidgetBody(
    BuildContext context,
    PillarInfo pillarInfo,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Lottie.asset(
            'assets/lottie/ic_anim_pillar.json',
            repeat: false,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Update Pillar settings',
                style: Theme.of(context).textTheme.headline6,
              ),
              kVerticalSpacing,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SyriusElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StepperScreen(
                            stepper: PillarUpdateStepper(pillarInfo),
                            onStepperNotificationSeeMorePressed:
                                widget.onStepperNotificationSeeMorePressed,
                          ),
                        ),
                      );
                    },
                    text: 'Update Pillar',
                    initialFillColor: AppColors.znnColor,
                    icon: _getFilledButtonIcon(),
                  ),
                ],
              ),
            ],
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
        MaterialCommunityIcons.plus,
        color: Colors.white,
        size: 15.0,
      ),
    );
  }

  @override
  void dispose() {
    _getPillarByOwnerBloc.dispose();
    super.dispose();
  }
}
