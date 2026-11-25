import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Creates a local encrypted wallet file linked to a Ledger hardware device
/// and then prompts for initial node configuration.
class CreateLedgerWalletScreen extends StatelessWidget {
  /// Creates a [CreateLedgerWalletScreen].
  const CreateLedgerWalletScreen(
    this._deviceInfo,
    this._password, {
    this._progressBarNumLevels = 4,
    this._ledgerWalletFileBloc,
    this._nodeManagementBuilder,
    super.key,
  });

  final WalletDefinition _deviceInfo;
  final String _password;
  final int _progressBarNumLevels;
  final LedgerWalletFileBloc? _ledgerWalletFileBloc;
  final Widget Function(VoidCallback onConfirmed)? _nodeManagementBuilder;

  @override
  Widget build(BuildContext context) {
    final Widget view = _View(
      progressBarNumLevels: _progressBarNumLevels,
      nodeManagementBuilder: _nodeManagementBuilder,
    );
    final LedgerWalletFileBloc? injectedBloc = _ledgerWalletFileBloc;
    if (injectedBloc != null) {
      return BlocProvider<LedgerWalletFileBloc>.value(
        value: injectedBloc,
        child: view,
      );
    }

    return BlocProvider<LedgerWalletFileBloc>(
      create: (_) => LedgerWalletFileBloc()
        ..add(
          LedgerWalletFileCreateRequested(
            walletId: _deviceInfo.walletId,
            password: _password,
            walletName: _deviceInfo.walletName,
          ),
        ),
      child: view,
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this._progressBarNumLevels,
    this._nodeManagementBuilder,
  });

  final int _progressBarNumLevels;
  final Widget Function(VoidCallback onConfirmed)? _nodeManagementBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: BlocBuilder<LedgerWalletFileBloc, LedgerWalletFileState>(
            builder: (BuildContext context, LedgerWalletFileState state) {
              return switch (state) {
                LedgerWalletFileSuccess() => _buildNodeManagement(context),
                LedgerWalletFileFailure(:final Object error) =>
                  SyriusErrorWidget(error),
                LedgerWalletFileInitial() ||
                LedgerWalletFileLoading() => const SyriusLoadingWidget(),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNodeManagement(BuildContext context) {
    void onConfirmed() {
      NavigationUtils.push(
        context,
        WalletSuccessScreen(progressBarNumLevels: _progressBarNumLevels),
      );
    }

    return Column(
      children: <Widget>[
        ProgressBar(
          currentLevel: _progressBarNumLevels - 1,
          numLevels: _progressBarNumLevels,
        ),
        Expanded(
          child: _nodeManagementBuilder != null
              ? _nodeManagementBuilder(onConfirmed)
              : NodeManagementScreen(nodeConfirmationCallback: onConfirmed),
        ),
      ],
    );
  }
}
