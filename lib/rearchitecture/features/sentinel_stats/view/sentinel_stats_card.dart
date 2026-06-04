import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Shows the current selected address sentinel status.
///
/// If the selected address does not own a sentinel, the card shows an action to
/// start the sentinel creation flow. If it already owns one, the card informs
/// the user that the address cannot be reused for another sentinel.
class SentinelStatsCard extends StatelessWidget {
  /// {@macro default_constructor}
  const SentinelStatsCard({
    required this._onStepperNotificationSeeMorePressed,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SentinelsByOwnerBloc>(
      create: (_) =>
          SentinelsByOwnerBloc(
            zenon: zenon!,
          )..add(
            FetchRequestData(
              address: Address.parse(kSelectedAddress!),
            ),
          ),
      child: _View(
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
      ),
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this.onStepperNotificationSeeMorePressed,
  });

  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      body: _buildBody(context),
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        context.read<SentinelsByOwnerBloc>().add(
          FetchRequestData(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
    );
  }

  CardData _buildCardData({required BuildContext context}) {
    return CardData(
      description: context.l10n.createSentinelDescription,
      title: context.l10n.sentinelStats,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Lottie.asset('assets/lottie/ic_anim_sentinel.json', repeat: false),
        Expanded(
          child: BlocBuilder<SentinelsByOwnerBloc, FetchState<List<SentinelInfo>>>(
            builder: (_, FetchState<List<SentinelInfo>> state) {
              return switch (state) {
                FetchFailure<List<SentinelInfo>>() => SyriusErrorWidget(
                  state.exception,
                ),
                FetchInitial<List<SentinelInfo>>() => const SyriusLoadingWidget(),
                FetchPopulated<List<SentinelInfo>>() =>
                  state.data.any(
                        (SentinelInfo sentinelInfo) => sentinelInfo.active,
                      )
                      ? _buildAlreadyCreatedSentinelWidgetBody(context)
                      : _buildCreateSentinelWidgetBody(context),
              };
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlreadyCreatedSentinelWidgetBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            context.l10n.sentinelDetectedOnThisAddress,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        StandardTooltipIcon(
          context.l10n.cannotReuseAddressForSentinel,
          Icons.help,
        ),
        kHorizontalGap16,
      ],
    );
  }

  Widget _buildCreateSentinelWidgetBody(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            unawaited(
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => StepperScreen(
                    stepper: const SentinelStepperContainer(),
                    onStepperNotificationSeeMorePressed:
                        onStepperNotificationSeeMorePressed,
                  ),
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
}
