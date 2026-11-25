import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Builds the Accelerator tab body from an [AcceleratorPillarState].
///
/// Renders [layoutBuilder] whenever resolution has populated — including when
/// `pillarInfo` is `null` (an ordinary account with no Pillar owner or
/// producer role) — so non-Pillar accounts are never stuck on the spinner.
@visibleForTesting
Widget buildAcceleratorTabBody(
  AcceleratorPillarState state,
  Widget Function(PillarInfo? pillarInfo, int? activePillarCount) layoutBuilder,
) {
  return switch (state) {
    AcceleratorPillarInitial() ||
    AcceleratorPillarLoading() => const SyriusLoadingWidget(),
    AcceleratorPillarFailure(:final SyriusException exception) =>
      SyriusErrorWidget(exception),
    AcceleratorPillarPopulated(
      :final PillarInfo? pillarInfo,
      :final int? activePillarCount,
    ) =>
      layoutBuilder(pillarInfo, activePillarCount),
  };
}

/// Displays the Accelerator-Z tab content in a responsive fluid layout.
class AcceleratorTabChild extends StatelessWidget {
  /// Creates an [AcceleratorTabChild].
  const AcceleratorTabChild({
    required this._onStepperNotificationSeeMorePressed,
    this._pillarBloc,
    this._balanceBloc,
    this._projectListBloc,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final AcceleratorPillarBloc? _pillarBloc;
  final AcceleratorBalanceBloc? _balanceBloc;
  final ProjectListBloc? _projectListBloc;

  @override
  Widget build(BuildContext context) {
    final AcceleratorPillarBloc? providedPillarBloc = _pillarBloc;
    final AcceleratorBalanceBloc? providedBalanceBloc = _balanceBloc;
    final ProjectListBloc? providedProjectListBloc = _projectListBloc;

    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        if (providedPillarBloc != null)
          BlocProvider<AcceleratorPillarBloc>.value(value: providedPillarBloc)
        else
          BlocProvider<AcceleratorPillarBloc>(
            create: (_) => AcceleratorPillarBloc(zenon: zenon!)
              ..add(
                AcceleratorPillarRequested(
                  address: Address.parse(kSelectedAddress!),
                ),
              ),
          ),
        if (providedBalanceBloc != null)
          BlocProvider<AcceleratorBalanceBloc>.value(value: providedBalanceBloc)
        else
          BlocProvider<AcceleratorBalanceBloc>(
            create: (_) =>
                AcceleratorBalanceBloc(zenon: zenon!)
                  ..add(const AcceleratorBalanceRequested()),
          ),
        if (providedProjectListBloc != null)
          BlocProvider<ProjectListBloc>.value(value: providedProjectListBloc)
        else
          BlocProvider<ProjectListBloc>(
            create: (_) => ProjectListBloc(zenon: zenon!),
          ),
      ],
      child: _View(
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
      ),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this._onStepperNotificationSeeMorePressed});

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  SelectedAddressNotifier? _addressNotifier;
  String? _lastSelectedAddress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SelectedAddressNotifier? notifier =
        Provider.of<SelectedAddressNotifier?>(context, listen: false);
    if (!identical(notifier, _addressNotifier)) {
      _addressNotifier?.removeListener(_onSelectedAddressChanged);
      _addressNotifier = notifier;
      _addressNotifier?.addListener(_onSelectedAddressChanged);
    }
    _lastSelectedAddress ??= kSelectedAddress;

    final AcceleratorPillarState pillarState = context
        .read<AcceleratorPillarBloc>()
        .state;
    if (pillarState is AcceleratorPillarPopulated &&
        context.read<ProjectListBloc>().state.status ==
            ProjectListStatus.initial) {
      context.read<ProjectListBloc>().add(
        ProjectListPillarUpdated(pillarInfo: pillarState.pillarInfo),
      );
    }
  }

  void _onSelectedAddressChanged() {
    final String? nextAddress = kSelectedAddress;
    if (nextAddress == null || nextAddress == _lastSelectedAddress) {
      return;
    }
    _lastSelectedAddress = nextAddress;
    if (mounted) {
      context.read<AcceleratorPillarBloc>().add(
        AcceleratorPillarRequested(address: Address.parse(nextAddress)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AcceleratorPillarBloc, AcceleratorPillarState>(
      listener: (BuildContext context, AcceleratorPillarState state) {
        if (state is AcceleratorPillarPopulated) {
          context.read<ProjectListBloc>().add(
            ProjectListPillarUpdated(pillarInfo: state.pillarInfo),
          );
        }
      },
      builder: (BuildContext context, AcceleratorPillarState state) {
        return buildAcceleratorTabBody(
          state,
          (PillarInfo? pillarInfo, int? activePillarCount) =>
              _buildLayout(context, pillarInfo, activePillarCount),
        );
      },
    );
  }

  StandardFluidLayout _buildLayout(
    BuildContext context,
    PillarInfo? pillarInfo,
    int? activePillarCount,
  ) {
    void refreshBalance() {
      if (context.mounted) {
        context.read<AcceleratorBalanceBloc>().add(
          const AcceleratorBalanceRequested(),
        );
      }
    }

    void refreshProjectsAndBalance() {
      if (context.mounted) {
        context.read<ProjectListBloc>().add(
          const ProjectListRequested(refresh: true),
        );
        context.read<AcceleratorBalanceBloc>().add(
          const AcceleratorBalanceRequested(),
        );
      }
    }

    return StandardFluidLayout(
      children: <FluidCell>[
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: AcceleratorDonationsCard(
            onStepperNotificationSeeMorePressed:
                widget._onStepperNotificationSeeMorePressed,
            onDonationSubmitted: refreshBalance,
          ),
        ),
        FluidCell(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: const AcceleratorStatsCard(),
        ),
        FluidCell(
          width: context.layout.value(
            lg: kStaggeredNumOfColumns ~/ 3,
            xl: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
          child: CreateProjectCard(
            onStepperNotificationSeeMorePressed:
                widget._onStepperNotificationSeeMorePressed,
            onProjectCreated: refreshProjectsAndBalance,
          ),
        ),
        FluidCell(
          width: kStaggeredNumOfColumns,
          height: kStaggeredNumOfColumns / 2,
          child: AcceleratorProjectsCard(
            onStepperNotificationSeeMorePressed:
                widget._onStepperNotificationSeeMorePressed,
            pillarInfo: pillarInfo,
            activePillarCount: activePillarCount,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _addressNotifier?.removeListener(_onSelectedAddressChanged);
    super.dispose();
  }
}
