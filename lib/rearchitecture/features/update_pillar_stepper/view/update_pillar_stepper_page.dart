import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class UpdatePillarStepperPage extends StatelessWidget {
  const UpdatePillarStepperPage({required PillarInfo pillarInfo, super.key})
    : _pillarInfo = pillarInfo;

  final PillarInfo _pillarInfo;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => UpdatePillarBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
          ),
        ),
      ],
      child: UpdatePillarStepperView(_pillarInfo),
    );
  }
}
