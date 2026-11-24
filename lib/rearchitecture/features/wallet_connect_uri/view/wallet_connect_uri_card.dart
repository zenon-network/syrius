import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Card allowing the user to paste or receive a WalletConnect v2 URI and
/// initiate pairing with a dApp.
class WalletConnectUriCard extends StatelessWidget {
  /// Creates a [WalletConnectUriCard].
  const WalletConnectUriCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletConnectPairBloc>(
      create: (_) =>
          WalletConnectPairBloc(web3WalletService: sl<IWeb3WalletService>()),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  late final TextEditingController _uriController;
  final GlobalKey<FormState> _uriKey = GlobalKey<FormState>();
  late String _lastObservedText;
  int _inputRevision = 0;
  int? _submittedInputRevision;

  @override
  void initState() {
    super.initState();
    final String? initialUri = kLastWalletConnectUriNotifier.value;
    _uriController = TextEditingController(text: initialUri);
    _lastObservedText = _uriController.text;
    if (initialUri != null) {
      kLastWalletConnectUriNotifier.value = null;
    }
    _uriController.addListener(_onUriTextChanged);
    kLastWalletConnectUriNotifier.addListener(_onExternalUriChanged);
  }

  @override
  void dispose() {
    kLastWalletConnectUriNotifier.removeListener(_onExternalUriChanged);
    _uriController
      ..removeListener(_onUriTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onUriTextChanged() {
    final String currentText = _uriController.text;
    if (currentText != _lastObservedText) {
      _lastObservedText = currentText;
      _inputRevision++;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onExternalUriChanged() {
    final String? incomingUri = kLastWalletConnectUriNotifier.value;
    if (incomingUri == null) {
      return;
    }
    kLastWalletConnectUriNotifier.value = null;
    if (mounted) {
      _uriController.text = incomingUri;
    }
  }

  bool get _hasValidUri =>
      extractWalletConnectUri(
        _uriController.text,
        isWindows: Platform.isWindows,
      ) !=
      null;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.walletConnectLink,
        description: context.l10n.pasteWalletConnectLinkHere,
      ),
      body: BlocConsumer<WalletConnectPairBloc, WalletConnectPairState>(
        listenWhen:
            (WalletConnectPairState previous, WalletConnectPairState current) =>
                previous.successCount != current.successCount ||
                (current.error != null &&
                    previous.errorCount != current.errorCount),
        listener: (BuildContext context, WalletConnectPairState state) {
          if (state.status == WalletConnectPairStatus.success) {
            final bool matchesSubmittedInput =
                _submittedInputRevision == _inputRevision;
            _submittedInputRevision = null;
            if (matchesSubmittedInput) {
              _uriKey.currentState?.reset();
              _uriController.clear();
            }
          } else if (state.status == WalletConnectPairStatus.failure) {
            _submittedInputRevision = null;
            final Object? error = state.error;
            if (error != null) {
              unawaited(
                NotificationUtils.sendNotificationError(
                  error,
                  context.l10n.pairingFailed,
                ),
              );
            }
          }
        },
        builder: (BuildContext context, WalletConnectPairState state) {
          final bool isLoading =
              state.status == WalletConnectPairStatus.loading;
          return _buildCardBody(context: context, isLoading: isLoading);
        },
      ),
    );
  }

  Widget _buildCardBody({
    required BuildContext context,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.link, color: AppColors.znnColor),
                ),
                _buildUriForm(context),
              ],
            ),
          ),
          _buildConnectButton(context: context, isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _buildUriForm(BuildContext context) {
    return Form(
      key: _uriKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: InputField(
        validator: (String? value) {
          if (extractWalletConnectUri(
                value ?? '',
                isWindows: Platform.isWindows,
              ) !=
              null) {
            return null;
          }
          return context.l10n.uriInvalid;
        },
        controller: _uriController,
        suffixIcon: PasteContentButton(controller: _uriController),
        hintText: context.l10n.walletConnectUri,
      ),
    );
  }

  Widget _buildConnectButton({
    required BuildContext context,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SyriusLoadingWidget(size: 24, strokeWidth: 2, padding: 2),
        ),
      );
    }

    return MyOutlinedButton(
      text: context.l10n.connect,
      onPressed: _hasValidUri
          ? () {
              _submittedInputRevision = _inputRevision;
              context.read<WalletConnectPairBloc>().add(
                WalletConnectPairRequested(
                  rawUri: _uriController.text,
                  isWindows: Platform.isWindows,
                ),
              );
            }
          : null,
      minimumSize: kLoadingButtonMinSize,
    );
  }
}
