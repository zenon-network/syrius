import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays all Settings cards in a responsive fluid layout.
class SettingsTabChild extends StatelessWidget {
  /// Creates a [SettingsTabChild].
  const SettingsTabChild(
    this._onChangeAutoLockTime, {
    required this._onStepperNotificationSeeMorePressed,
    required this._onNodeChangedCallback,
    super.key,
  });

  final VoidCallback _onChangeAutoLockTime;
  final VoidCallback _onStepperNotificationSeeMorePressed;
  final VoidCallback _onNodeChangedCallback;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountChainStatsBloc>(
      create: (_) {
        final AccountChainStatsBloc bloc = AccountChainStatsBloc(zenon: zenon!);
        final String? selectedAddress = kSelectedAddress;
        if (selectedAddress != null) {
          bloc.add(FetchRequestData(address: Address.parse(selectedAddress)));
        }
        return bloc;
      },
      child: StandardFluidLayout(
        defaultCellWidth: context.layout.value(
          xl: kStaggeredNumOfColumns ~/ 4,
          lg: kStaggeredNumOfColumns ~/ 4,
          md: kStaggeredNumOfColumns ~/ 4,
          sm: kStaggeredNumOfColumns,
          xs: kStaggeredNumOfColumns,
        ),
        children: <FluidCell>[
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 2,
              lg: kStaggeredNumOfColumns ~/ 2,
              md: kStaggeredNumOfColumns ~/ 2,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            child: const SettingsAddressesCard(),
          ),
          const FluidCell(child: SettingsGeneralCard()),
          const FluidCell(child: AccountChainStatsCard()),
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 2,
              lg: kStaggeredNumOfColumns ~/ 2,
              md: kStaggeredNumOfColumns ~/ 2,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            height: kStaggeredNumOfColumns / 4,
            child: NodeManagementCard(
              onNodeChangedCallback: _onNodeChangedCallback,
            ),
          ),
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 6,
              lg: kStaggeredNumOfColumns ~/ 6,
              md: kStaggeredNumOfColumns ~/ 6,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            height: kStaggeredNumOfColumns / 2,
            child: SettingsSecurityCard(
              onChangeAutoLockTime: _onChangeAutoLockTime,
              onStepperNotificationSeeMorePressed:
                  _onStepperNotificationSeeMorePressed,
            ),
          ),
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 6,
              lg: kStaggeredNumOfColumns ~/ 6,
              md: kStaggeredNumOfColumns ~/ 6,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            height: kStaggeredNumOfColumns / 2,
            child: const SettingsDisplayCard(),
          ),
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 6,
              lg: kStaggeredNumOfColumns ~/ 6,
              md: kStaggeredNumOfColumns ~/ 6,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            height: kStaggeredNumOfColumns / 4,
            child: const SettingsWalletOptionsCard(),
          ),
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 2,
              lg: kStaggeredNumOfColumns ~/ 2,
              md: kStaggeredNumOfColumns ~/ 2,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            child: const PeersCard(),
          ),
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 6,
              lg: kStaggeredNumOfColumns ~/ 6,
              md: kStaggeredNumOfColumns ~/ 6,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            height: kStaggeredNumOfColumns / 4,
            child: const SettingsBackupCard(),
          ),
        ],
      ),
    );
  }
}
