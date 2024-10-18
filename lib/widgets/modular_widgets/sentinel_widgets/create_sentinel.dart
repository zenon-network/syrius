import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreateSentinel extends StatefulWidget {

  const CreateSentinel({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<CreateSentinel> createState() => _CreateSentinelState();
}

class _CreateSentinelState extends State<CreateSentinel> {
  final GetSentinelByOwnerBloc _getSentinelByOwnerBloc =
      GetSentinelByOwnerBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Create Sentinel',
      description: 'Start the process of deploying a Sentinel Node in the '
          'network',
      childBuilder: () => _getStreamBuilder(context),
    );
  }

  Widget _getStreamBuilder(BuildContext context) {
    return StreamBuilder<SentinelInfo?>(
      stream: _getSentinelByOwnerBloc.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData && snapshot.data!.active) {
            return _getAlreadyCreatedSentinelWidgetBody(context);
          } else {
            return _getCreateSentinelWidgetBody(context);
          }
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Center _getAlreadyCreatedSentinelWidgetBody(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sentinel detected on this address',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const StandardTooltipIcon(
            'Cannot reuse address.\n'
            'Please use another address to spawn a new Sentinel Node',
            Icons.help,
          ),
        ],
      ),
    );
  }

  Row _getCreateSentinelWidgetBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Lottie.asset('assets/lottie/ic_anim_sentinel.json', repeat: false),
        SyriusElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StepperScreen(
                  stepper: const SentinelStepperContainer(),
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
        const SizedBox(
          width: 10,
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
        MaterialCommunityIcons.eye,
        color: Colors.white,
        size: 15,
      ),
    );
  }

  @override
  void dispose() {
    _getSentinelByOwnerBloc.dispose();
    super.dispose();
  }
}
