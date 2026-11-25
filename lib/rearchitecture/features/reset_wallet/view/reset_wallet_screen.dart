import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/reset_wallet/reset_wallet.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Confirmation screen before permanently erasing wallet files, cache, and
/// P2P HTLC swaps via [SplashScreen].
class ResetWalletScreen extends StatelessWidget {
  /// Creates a [ResetWalletScreen].
  const ResetWalletScreen({
    super.key,
    this._cubit,
    this._onNavigateToResetSplash,
  });

  final ResetWalletCubit? _cubit;
  final VoidCallback? _onNavigateToResetSplash;

  @override
  Widget build(BuildContext context) {
    final ResetWalletCubit? injected = _cubit;
    final Widget view = _View(
      onNavigateToResetSplash: _onNavigateToResetSplash,
    );
    if (injected != null) {
      return BlocProvider<ResetWalletCubit>.value(value: injected, child: view);
    }

    return BlocProvider<ResetWalletCubit>(
      create: (_) => ResetWalletCubit(),
      child: view,
    );
  }
}

class _View extends StatelessWidget {
  const _View({this._onNavigateToResetSplash});

  final VoidCallback? _onNavigateToResetSplash;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ResetWalletCubit, ResetWalletState>(
        listener: (BuildContext context, ResetWalletState state) {
          if (state is ResetWalletReadyToNavigate) {
            final VoidCallback? override = _onNavigateToResetSplash;
            if (override != null) {
              override();
              return;
            }
            // SplashScreen._resetWallet clears cache, Drift HTLC swap DB,
            // legacy swap boxes, and the wallet file.
            Navigator.of(context).pushAndRemoveUntil<void>(
              MaterialPageRoute<void>(
                builder: (_) => const SplashScreen(resetWalletFlow: true),
              ),
              (Route<dynamic> route) => false,
            );
          }
        },
        builder: (BuildContext context, ResetWalletState state) {
          final bool isResetting = state is ResetWalletInProgress;
          return Column(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildWarningIcon(),
                    kVerticalSpacing,
                    Text(
                      context.l10n.resetWallet,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    kVerticalSpacing,
                    SizedBox(
                      width: 500,
                      child: Text(
                        context.l10n.allWalletDataErasedPermanently,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButtons(context, isResetting: isResetting),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWarningIcon() {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 4, color: AppColors.errorColor),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Icon(
          Feather.alert_triangle,
          color: AppColors.errorColor,
          size: 50,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required bool isResetting,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        MyOutlinedButton(
          onPressed: isResetting
              ? null
              : () {
                  Navigator.pop(context);
                },
          outlineColor: Colors.white,
          text: context.l10n.cancel,
          minimumSize: const Size(100, 40),
        ),
        const SizedBox(width: 20),
        MyOutlinedButton(
          outlineColor: AppColors.errorColor,
          onPressed: isResetting
              ? null
              : () {
                  unawaited(context.read<ResetWalletCubit>().confirmReset());
                },
          text: context.l10n.reset,
          textColor: AppColors.errorColor,
          minimumSize: const Size(100, 40),
        ),
      ],
    );
  }
}
