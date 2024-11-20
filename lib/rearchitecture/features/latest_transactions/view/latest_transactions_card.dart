import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class LatestTransactionsCard extends StatelessWidget {
  const LatestTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardType.latestTransactions.getData(context: context),
      onRefreshPressed: () {
        context.read<LatestTransactionsBloc>().add(
              LatestTransactionsRefreshRequested(
                address: Address.parse(kSelectedAddress!),
              ),
            );
      },
      body: BlocBuilder<LatestTransactionsBloc, LatestTransactionsState>(
        builder: (_, LatestTransactionsState state) {
          final LatestTransactionsStatus status = state.status;

          return switch (status) {
            LatestTransactionsStatus.initial =>
              const _LatestTransactionsInitial(),
            LatestTransactionsStatus.failure => _LatestTransactionsFailure(
                exception: state.error!,
              ),
            LatestTransactionsStatus.success =>
              const _LatestTransactionsPopulated(),
          };
        },
      ),
    );
  }
}

class _LatestTransactionsInitial extends StatelessWidget {
  const _LatestTransactionsInitial();

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}

class _LatestTransactionsFailure extends StatelessWidget {
  const _LatestTransactionsFailure({required this.exception});

  final SyriusException exception;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(exception);
  }
}

class _LatestTransactionsPopulated extends StatelessWidget {
  const _LatestTransactionsPopulated();

  @override
  Widget build(BuildContext context) {
    return Text('populated');
  }
}
