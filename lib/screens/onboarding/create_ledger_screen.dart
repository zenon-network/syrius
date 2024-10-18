import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/ledger_wallet_file_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreateLedgerWalletScreen extends StatefulWidget {

  const CreateLedgerWalletScreen(
    this.deviceInfo,
    this.password, {
    this.progressBarNumLevels = 4,
    super.key,
  });
  final WalletDefinition deviceInfo;
  final String password;
  final int progressBarNumLevels;

  @override
  State<CreateLedgerWalletScreen> createState() =>
      _CreateLedgerWalletScreenState();
}

class _CreateLedgerWalletScreenState extends State<CreateLedgerWalletScreen> {
  late LedgerWalletFileBloc _ledgerWalletFileBloc;

  @override
  void initState() {
    super.initState();
    _ledgerWalletFileBloc = LedgerWalletFileBloc()
      ..getLedgerWalletPath(
        widget.deviceInfo.walletId,
        widget.password,
        widget.deviceInfo.walletName,
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
          child: StreamBuilder<LedgerWalletFile?>(
            stream: _ledgerWalletFileBloc.stream,
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
