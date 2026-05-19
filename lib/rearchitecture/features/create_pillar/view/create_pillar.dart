import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreatePillar extends StatefulWidget {
  const CreatePillar({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });

  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<CreatePillar> createState() => _CreatePillarState();
}

class _CreatePillarState extends State<CreatePillar> {
  final GetPillarByOwnerBloc _getPillarByOwnerBloc = GetPillarByOwnerBloc();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      body: _getStreamBuilder(context),
      data: _buildCardData(context: context),
    );
  }

  CardData _buildCardData({required BuildContext context}) {
    return CardData(
      description: context.l10n.createPillarDescription,
      title: context.l10n.createPillarTitle,
    );
  }

  Widget _getStreamBuilder(BuildContext context) {
    return StreamBuilder<List<PillarInfo>>(
      stream: _getPillarByOwnerBloc.stream,
      builder: (_, AsyncSnapshot<List<PillarInfo>> snapshot) {
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
      children: <Widget>[
        Lottie.asset('assets/lottie/ic_anim_pillar.json', repeat: false),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => StepperScreen(
                      stepper: const PillarStepperContainer(),
                      onStepperNotificationSeeMorePressed:
                          widget.onStepperNotificationSeeMorePressed,
                    ),
                  ),
                );
              },
              label: Text(context.l10n.spawn),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(
          width: 10,
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
      children: <Widget>[
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
            children: <Widget>[
              Text(
                context.l10n.updatePillarSettings,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              kVerticalSpacing,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SyriusElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => StepperScreen(
                            stepper: PillarUpdateStepper(pillarInfo),
                            onStepperNotificationSeeMorePressed:
                                widget.onStepperNotificationSeeMorePressed,
                          ),
                        ),
                      );
                    },
                    text: context.l10n.updatePillar,
                    initialFillColor: AppColors.znnColor,
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _getPillarByOwnerBloc.dispose();
    super.dispose();
  }
}
