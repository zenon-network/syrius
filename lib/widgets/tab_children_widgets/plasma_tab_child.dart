import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_generated_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class PlasmaTabChild extends StatefulWidget {
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
    sl.get<PlasmaStatsBloc>().getPlasmas();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlasmaInfoWrapper>>(
      stream: sl.get<PlasmaStatsBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return _getFluidLayout([], errorText: snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return _getFluidLayout(snapshot.data!);
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getFluidLayout(
    List<PlasmaInfoWrapper> plasmaStatsResults, {
    String? errorText,
  }) {
    return StandardFluidLayout(
      children: [
        FluidCell(
          child: Consumer<PlasmaGeneratedNotifier>(
            builder: (_, __, ___) => const PlasmaStats(
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
          child: PlasmaOptions(
            plasmaListBloc: _plasmaListBloc,
            plasmaStatsResults: plasmaStatsResults,
            errorText: errorText,
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
