import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_general/settings_general.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays general wallet and network metrics in the Settings tab.
class SettingsGeneralCard extends StatelessWidget {
  /// Creates a [SettingsGeneralCard].
  const SettingsGeneralCard({super.key, this._cubit});

  final SettingsGeneralCubit? _cubit;

  @override
  Widget build(BuildContext context) {
    final SettingsGeneralCubit? injected = _cubit;
    if (injected != null) {
      return BlocProvider<SettingsGeneralCubit>.value(
        value: injected,
        child: const _View(),
      );
    }

    return BlocProvider<SettingsGeneralCubit>(
      create: (_) {
        final SettingsGeneralCubit cubit = SettingsGeneralCubit(zenon: zenon!);
        unawaited(cubit.fetchDataPeriodically());
        return cubit;
      },
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final ValueNotifier<bool> _isRefreshing = ValueNotifier<bool>(false);

  Future<void> _onRefreshPressed() async {
    if (_isRefreshing.value) {
      return;
    }
    _isRefreshing.value = true;
    try {
      await context.read<SettingsGeneralCubit>().fetchDataPeriodically();
    } finally {
      if (mounted) {
        _isRefreshing.value = false;
      }
    }
  }

  @override
  void dispose() {
    _isRefreshing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      isRefreshLoading: _isRefreshing,
      onRefreshPressed: () {
        unawaited(_onRefreshPressed());
      },
      body: BlocBuilder<SettingsGeneralCubit, SettingsGeneralState>(
        builder: (BuildContext context, SettingsGeneralState state) {
          return switch (state.status) {
            TimerStatus.initial ||
            TimerStatus.loading => const SyriusLoadingWidget(),
            TimerStatus.failure => SyriusErrorWidget(state.error!),
            TimerStatus.success => _Populated(data: state.data!),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.general,
    description: context.l10n.genericWalletAndNetworkInfo,
  );
}

class _Populated extends StatelessWidget {
  const _Populated({required this._data});

  final SettingsGeneralData _data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text(
                context.l10n.momentumHeight,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              _buildMomentumHeightCircle(context),
              const SizedBox(height: 10),
              _buildPeersRow(context),
              const SizedBox(height: 10),
              _buildTimestampRow(context),
              const SizedBox(height: 6),
              _buildMomentumHashButton(context),
              _buildMomentumHashMarquee(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMomentumHeightCircle(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: const ShapeDecoration(
        color: Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(width: 6, color: AppColors.znnColor),
        ),
      ),
      child: Center(
        child: NumberAnimation(
          end: _data.momentumHeight,
          isInt: true,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }

  Widget _buildPeersRow(BuildContext context) {
    final bool hasPeers = _data.peerCount > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          hasPeers
              ? MaterialCommunityIcons.lan_connect
              : MaterialCommunityIcons.lan_disconnect,
          size: 15,
          color: hasPeers ? AppColors.znnColor : AppColors.errorColor,
        ),
        const SizedBox(width: 4),
        Text(
          hasPeers ? context.l10n.peersConnected : context.l10n.peersAvailable,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 10),
        Text(
          hasPeers ? '${_data.peerCount}' : context.l10n.noPeersFound,
          style: hasPeers
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTimestampRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(
          MaterialCommunityIcons.timer,
          size: 15,
          color: AppColors.qsrColor,
        ),
        const SizedBox(width: 4),
        Text(
          context.l10n.timestamp,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 10),
        Text(
          '${_data.momentumTimestamp}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildMomentumHashButton(BuildContext context) {
    return RawMaterialButton(
      constraints: const BoxConstraints(minHeight: 40),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () {
        unawaited(
          NavigationUtils.openUrl('$kExplorer/momentum/${_data.momentumHash}'),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            context.l10n.momentumHash,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 10),
          const Icon(
            MaterialCommunityIcons.compass,
            size: 20,
            color: AppColors.znnColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMomentumHashMarquee(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 12, right: 22, left: 22),
            child: Marquee(
              child: Text(
                _data.momentumHash,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
