import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Creates an encrypted keystore file from a mnemonic and then prompts for
/// initial node configuration.
class CreateKeyStoreScreen extends StatelessWidget {
  /// Creates a [CreateKeyStoreScreen].
  const CreateKeyStoreScreen(
    this._seed,
    this._password, {
    this._progressBarNumLevels = 5,
    this._keyStoreFileBloc,
    this._nodeManagementBuilder,
    super.key,
  });

  final String _seed;
  final String _password;
  final int _progressBarNumLevels;
  final KeyStoreFileBloc? _keyStoreFileBloc;
  final Widget Function(VoidCallback onConfirmed)? _nodeManagementBuilder;

  @override
  Widget build(BuildContext context) {
    final Widget view = _View(
      progressBarNumLevels: _progressBarNumLevels,
      nodeManagementBuilder: _nodeManagementBuilder,
    );
    final KeyStoreFileBloc? injectedBloc = _keyStoreFileBloc;
    if (injectedBloc != null) {
      return BlocProvider<KeyStoreFileBloc>.value(
        value: injectedBloc,
        child: view,
      );
    }

    return BlocProvider<KeyStoreFileBloc>(
      create: (_) => KeyStoreFileBloc()
        ..add(
          KeyStoreFileCreateRequested(mnemonic: _seed, password: _password),
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
          child: BlocBuilder<KeyStoreFileBloc, KeyStoreFileState>(
            builder: (BuildContext context, KeyStoreFileState state) {
              return switch (state) {
                KeyStoreFileSuccess() => _buildNodeManagement(context),
                KeyStoreFileFailure(:final Object error) => SyriusErrorWidget(
                  error,
                ),
                KeyStoreFileInitial() ||
                KeyStoreFileLoading() => const SyriusLoadingWidget(),
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
