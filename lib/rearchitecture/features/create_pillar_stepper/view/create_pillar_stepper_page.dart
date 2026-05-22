import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';

class CreatePillarStepperPage extends StatelessWidget {
  const CreatePillarStepperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<CreatePillarQsrInfoBloc>(
          create: (_) => CreatePillarQsrInfoBloc(zenon: zenon!),
        ),
        BlocProvider<PillarWithdrawQsrBloc>(
          create: (_) => PillarWithdrawQsrBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
        BlocProvider<PillarDepositQsrBloc>(
          create: (_) => PillarDepositQsrBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
        BlocProvider<DeployPillarBloc>(
          create: (_) => DeployPillarBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
      ],
      child: const CreatePillarStepperView(),
    );
  }
}
