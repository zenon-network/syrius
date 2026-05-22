import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
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

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      body: _buildBody(context),
      data: _buildCardData(context: context),
      onRefreshPressed: () async {
        context.read<GetPillarsByOwnerBloc>().add(
          FetchRequestData(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
    );
  }

  CardData _buildCardData({required BuildContext context}) {
    return CardData(
      description: context.l10n.createPillarDescription,
      title: context.l10n.createPillarTitle,
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<GetPillarsByOwnerBloc, FetchState<List<PillarInfo>>>(
      builder: (_, FetchState<List<PillarInfo>> state) {
        return switch (state) {
          FetchFailure<List<PillarInfo>>() => SyriusErrorWidget(
              state.exception,
            ),
          FetchInitial<List<PillarInfo>>() => const SyriusLoadingWidget(),
          FetchPopulated<List<PillarInfo>>() => state.data.isNotEmpty
              ? _getUpdatePillarWidgetBody(context, state.data.first)
              : _getCreatePillarWidgetBody(context),
        };
      },
    );
  }

  Widget _getCreatePillarWidgetBody(BuildContext context) {
    return Row(
      children: <Widget>[
        Lottie.asset('assets/lottie/ic_anim_pillar.json', repeat: false),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => StepperScreen(
                  stepper: const CreatePillarStepperPage(),
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
    );
  }

  Widget _getUpdatePillarWidgetBody(
    BuildContext context,
    PillarInfo pillarInfo,
  ) {
    return Row(
      children: <Widget>[
        Lottie.asset(
          'assets/lottie/ic_anim_pillar.json',
          repeat: false,
        ),
        ElevatedButton.icon(
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
          label: Text(context.l10n.updatePillar),
          icon: const Icon(Icons.edit),
        ),
      ],
    );
  }
}
