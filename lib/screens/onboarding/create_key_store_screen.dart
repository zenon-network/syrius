import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class CreateKeyStoreScreen extends StatefulWidget {

  const CreateKeyStoreScreen(
    this.seed,
    this.password, {
    this.progressBarNumLevels = 5,
    super.key,
  });
  final String seed;
  final String password;
  final int progressBarNumLevels;

  @override
  State<CreateKeyStoreScreen> createState() => _CreateKeyStoreScreenState();
}

class _CreateKeyStoreScreenState extends State<CreateKeyStoreScreen> {
  late KeyStoreFileBloc _keyStoreFileBloc;

  @override
  void initState() {
    super.initState();
    _keyStoreFileBloc = KeyStoreFileBloc()
      ..getKeyStorePath(
        widget.seed,
        widget.password,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: Center(
          child: StreamBuilder<KeyStoreWalletFile?>(
            stream: _keyStoreFileBloc.stream,
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    ProgressBar(
                      currentLevel: widget.progressBarNumLevels - 1,
                      numLevels: widget.progressBarNumLevels,
                    ),
                    Expanded(
                      child: NodeManagementScreen(
                        nodeConfirmationCallback: () {
                          NavigationUtils.push(
                            context,
                            WalletSuccessScreen(
                              progressBarNumLevels: widget.progressBarNumLevels,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return SyriusErrorWidget(snapshot.error!);
              }
              return const SyriusLoadingWidget();
            },
          ),
        ),
      ),
    );
  }
}
