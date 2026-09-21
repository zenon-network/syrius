import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that listens to state updates from the [AllTokensBloc] and rebuilds,
/// feeding a specific widget for each [AllTokensState].
class ReceiveCard extends StatelessWidget {
  /// Creates a new instance.
  const ReceiveCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        context.read<AllTokensBloc>().add(const AllTokensRequested());
      },
      body: BlocBuilder<AllTokensBloc, AllTokensState>(
        builder: (_, AllTokensState state) {
          return switch (state) {
            AllTokensFailure(:final SyriusException exception) => ReceiveError(
              error: exception,
            ),
            AllTokensInitial() => const ReceiveInitial(),
            AllTokensPopulated(:final List<Token> data) => ReceivePopulated(
              assets: data,
            ),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    description: context.l10n.manageReceivingFunds,
    title: context.l10n.receive,
  );
}
