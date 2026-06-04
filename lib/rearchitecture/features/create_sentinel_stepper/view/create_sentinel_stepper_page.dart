import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// A wrapper widget that registers create sentinel stepper dependencies.
class CreateSentinelStepperPage extends StatelessWidget {
  /// {@macro default_constructor}
  const CreateSentinelStepperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<CreateSentinelQsrInfoBloc>(
          create: (_) => CreateSentinelQsrInfoBloc(zenon: zenon!),
        ),
        BlocProvider<SentinelWithdrawQsrBloc>(
          create: (_) => SentinelWithdrawQsrBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
        BlocProvider<SentinelDepositQsrBloc>(
          create: (_) => SentinelDepositQsrBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
        BlocProvider<DeploySentinelBloc>(
          create: (_) => DeploySentinelBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
      ],
      child: const CreateSentinelStepperView(),
    );
  }
}
