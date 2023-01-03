import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class CreateKeyStoreScreen extends StatefulWidget {
  final String seed;
  final String password;
  final int progressBarNumLevels;

  const CreateKeyStoreScreen(
    this.seed,
    this.password, {
    this.progressBarNumLevels = 5,
    Key? key,
  }) : super(key: key);

  @override
  State<CreateKeyStoreScreen> createState() => _CreateKeyStoreScreenState();
}

class _CreateKeyStoreScreenState extends State<CreateKeyStoreScreen> {
  late KeyStorePathBloc _keyStorePathBloc;

  @override
  void initState() {
    super.initState();
    _keyStorePathBloc = KeyStorePathBloc()
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
          vertical: 30.0,
        ),
        child: Center(
          child: StreamBuilder<String?>(
            stream: _keyStorePathBloc.stream,
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
