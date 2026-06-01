import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that helps with DI
class UpdatePillarStepperPage extends StatelessWidget {
  /// {@macro default_constructor}
  const UpdatePillarStepperPage({required PillarInfo pillarInfo, super.key})
    : _pillarInfo = pillarInfo;

  final PillarInfo _pillarInfo;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<UpdatePillarBloc>(
          create: (_) => UpdatePillarBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
          ),
        ),
      ],
      child: UpdatePillarStepperView(pillarInfo: _pillarInfo),
    );
  }
}
