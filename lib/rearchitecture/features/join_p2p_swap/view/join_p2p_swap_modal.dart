import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart' show BaseModal, BuildContextExtension;
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Modal containing the flow used to join a native P2P swap.
class JoinP2pSwapModal extends StatelessWidget {
  /// Creates a [JoinP2pSwapModal].
  const JoinP2pSwapModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<JoinP2pSwapBloc>(
          create: (_) => JoinP2pSwapBloc(
            accountBlockUtils: AccountBlockUtils(
              publishSuccessNotification: false,
            ),
            swapRepository: sl<HtlcSwapRepository>(),
            zenon: zenon!,
            zenonAddressUtils: ZenonAddressUtils(),
          ),
        ),
        BlocProvider<InitialHtlcValidationBloc>(
          create: (_) => InitialHtlcValidationBloc(
            accountBlocksAfterTimeFetcher:
                AccountBlockUtils.getAccountBlocksAfterTime,
            htlcSwapRepository: sl<HtlcSwapRepository>(),
            walletAddresses: kDefaultAddressList.whereType<String>().toSet(),
            zenon: zenon!,
          ),
        ),
      ],
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: context.l10n.joinSwap,
      child: BlocBuilder<InitialHtlcValidationBloc, InitialHtlcValidationState>(
        builder: (_, InitialHtlcValidationState state) => switch (state) {
          InitialHtlcValidationDone(
            :final AccountInfo accountInfo,
            :final HtlcInfo htlc,
            :final Token token,
          ) =>
            JoinP2pSwapForm(
              accountInfo: accountInfo,
              initialHtlc: htlc,
              token: token,
            ),
          _ => const InitialHtlcValidationForm(),
        },
      ),
    );
  }
}
