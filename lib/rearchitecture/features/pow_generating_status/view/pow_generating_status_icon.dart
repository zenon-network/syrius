import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pow_generating_status/bloc/pow_generating_status_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// Displays the current PoW plasma generation status as a navigation bar icon.
class PowGeneratingStatusIcon extends StatelessWidget {
  /// Creates a [PowGeneratingStatusIcon].
  const PowGeneratingStatusIcon({this._bloc, super.key});

  final PowGeneratingStatusBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    return _View(bloc: _bloc ?? sl.get<PowGeneratingStatusBloc>());
  }
}

class _View extends StatelessWidget {
  const _View({required this._bloc});

  final PowGeneratingStatusBloc _bloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PowGeneratingStatusBloc, PowGeneratingStatusState>(
      bloc: _bloc,
      builder: (BuildContext context, PowGeneratingStatusState state) {
        if (state.isGenerating) {
          return _buildGeneratingIcon(context);
        }
        return _buildIdleIcon(context);
      },
    );
  }

  Widget _buildGeneratingIcon(BuildContext context) {
    return Tooltip(
      message: context.l10n.generatingPlasma,
      child: Lottie.asset(
        'assets/lottie/ic_anim_plasma_generation.json',
        fit: BoxFit.contain,
        width: 30,
        repeat: true,
      ),
    );
  }

  Widget _buildIdleIcon(BuildContext context) {
    return Tooltip(
      message: context.l10n.plasmaGenerationIdle,
      child: Icon(
        MaterialCommunityIcons.lightning_bolt,
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}
