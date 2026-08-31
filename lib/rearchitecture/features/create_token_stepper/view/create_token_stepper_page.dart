import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// A wrapper widget that registers create token stepper dependencies.
class CreateTokenStepperPage extends StatelessWidget {
  /// Creates a [CreateTokenStepperPage].
  const CreateTokenStepperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<FavoriteTokensRepository>(
      create: (_) => HiveFavoriteTokensRepository(),
      child: MultiBlocProvider(
        providers: <SingleChildWidget>[
          BlocProvider<IssueTokenBloc>(
            create: (_) => IssueTokenBloc(
              accountBlockUtils: AccountBlockUtils(),
              zenon: zenon!,
              zenonAddressUtils: ZenonAddressUtils(),
            ),
          ),
        ],
        child: const CreateTokenStepperView(),
      ),
    );
  }
}
