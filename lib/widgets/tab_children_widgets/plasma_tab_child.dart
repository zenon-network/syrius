import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_generated_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Tab content for Plasma-related cards and lists.
class PlasmaTabChild extends StatefulWidget {
  /// Creates a Plasma tab child.
  const PlasmaTabChild({super.key});

  @override
  State createState() {
    return _PlasmaTabChildState();
  }
}

class _PlasmaTabChildState extends State<PlasmaTabChild> {
  late PlasmaListBloc _plasmaListBloc;

  @override
  void initState() {
    super.initState();
    _plasmaListBloc = PlasmaListBloc();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlasmaStatsBloc, InfiniteListState<PlasmaInfoWrapper>>(
      builder: (_, InfiniteListState<PlasmaInfoWrapper> state) {
        final InfiniteListStatus status = state.status;

        return switch (status) {
          InfiniteListStatus.initial => const SyriusLoadingWidget(),
          InfiniteListStatus.failure => _getFluidLayout(
            errorText: state.error.toString(),
          ),
          InfiniteListStatus.success => _getFluidLayout(
            plasmaStatsResults: state.data,
          ),
        };
      },
    );
  }

  Widget _getFluidLayout({
    List<PlasmaInfoWrapper>? plasmaStatsResults,
    String? errorText,
  }) {
    return StandardFluidLayout(
      children: <FluidCell>[
        FluidCell(
          child: Consumer<PlasmaGeneratedNotifier>(
            builder: (_, _, _) => const PlasmaStatsCard(
              version: PlasmaStatsWidgetVersion.plasmaTab,
            ),
          ),
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
        ),
        FluidCell(
          child: FusePlasmaCard(
            plasmaStatsResults: plasmaStatsResults,
            errorText: errorText,
            onPlasmaFused: _plasmaListBloc.refreshResults,
          ),
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 1.5,
            lg: kStaggeredNumOfColumns ~/ 1.5,
            md: kStaggeredNumOfColumns ~/ 1.5,
            sm: kStaggeredNumOfColumns,
            xs: kStaggeredNumOfColumns,
          ),
        ),
        FluidCell(
          child: PlasmaList(
            bloc: _plasmaListBloc,
            errorText: errorText,
          ),
          width: kStaggeredNumOfColumns,
          height: kStaggeredNumOfColumns / 2,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _plasmaListBloc.dispose();
    super.dispose();
  }
}
