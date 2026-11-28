import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Animated startup screen matching mockups Screens 39–40.
class SplashScreen extends StatelessWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({
    this._resetWalletFlow = false,
    this._deleteCacheFlow = false,
    this._splashBloc,
    this._compositionFuture,
    this._initApp,
    super.key,
  });

  /// Named route for [SplashScreen].
  static const String route = 'splash-screen';

  final bool _resetWalletFlow;
  final bool _deleteCacheFlow;
  final SplashBloc? _splashBloc;
  final Future<LottieComposition>? _compositionFuture;
  final Future<void> Function(BuildContext context)? _initApp;

  @override
  Widget build(BuildContext context) {
    final SplashFlow flow = _resetWalletFlow
        ? SplashFlow.resetWallet
        : _deleteCacheFlow
        ? SplashFlow.deleteCache
        : SplashFlow.normal;

    final Widget view = _View(
      flow: flow,
      compositionFuture: _compositionFuture,
      initApp: _initApp ?? InitUtils.initApp,
    );

    final SplashBloc? injectedBloc = _splashBloc;
    if (injectedBloc != null) {
      return BlocProvider<SplashBloc>.value(value: injectedBloc, child: view);
    }

    return BlocProvider<SplashBloc>(create: (_) => SplashBloc(), child: view);
  }
}

class _View extends StatefulWidget {
  const _View({
    required this._flow,
    required this._initApp,
    this._compositionFuture,
  });

  final SplashFlow _flow;
  final Future<void> Function(BuildContext context) _initApp;
  final Future<LottieComposition>? _compositionFuture;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  late final Future<LottieComposition> _composition;
  final FocusNode _focusNode = FocusNode();
  Timer? _initTimer;
  bool _initScheduled = false;
  bool _flowStarted = false;

  @override
  void initState() {
    super.initState();
    _composition =
        widget._compositionFuture ??
        AssetLottie('assets/lottie/ic_anim_splash.json').load();
    unawaited(_scheduleInitializationOnLoad());
  }

  Future<void> _scheduleInitializationOnLoad() async {
    try {
      final LottieComposition composition = await _composition;
      if (!mounted || _initScheduled || _flowStarted) {
        return;
      }
      _initScheduled = true;
      _initTimer = Timer(composition.duration, () {
        if (!mounted) {
          return;
        }
        _startSplashFlow();
      });
    } on Object catch (_) {
      if (!mounted || _initScheduled || _flowStarted) {
        return;
      }
      _initScheduled = true;
      _startSplashFlow();
    }
  }

  void _skipIntro() {
    if (_flowStarted) {
      return;
    }
    _initTimer?.cancel();
    _initScheduled = true;
    _startSplashFlow();
  }

  void _startSplashFlow({bool force = false}) {
    if (_flowStarted && !force) {
      return;
    }
    _flowStarted = true;
    context.read<SplashBloc>().add(
      SplashStarted(
        flow: widget._flow,
        initApp: () async {
          if (mounted) {
            await widget._initApp(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: _onSplashStateChanged,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent) {
            _skipIntro();
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skipIntro,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                const Positioned(
                  top: 16,
                  left: 18,
                  child: Text(
                    'S Y R I U S',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 3.5,
                      color: Colors.white38,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Center(
                  child: FutureBuilder<LottieComposition>(
                    future: _composition,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<LottieComposition> snapshot,
                        ) {
                          final LottieComposition? composition = snapshot.data;
                          if (composition != null) {
                            return Lottie(
                              composition: composition,
                              repeat: false,
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      context.l10n.clickOrPressAKeyToSkip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSplashStateChanged(BuildContext context, SplashState state) {
    switch (state) {
      case SplashNavigateTo(:final SplashDestination destination):
        _navigateTo(context, destination);
      case SplashFailure(:final Object error, :final bool failedWhileClearing):
        unawaited(
          _handleSplashFailure(error, failedWhileClearing: failedWhileClearing),
        );
      case SplashInitial():
      case SplashInProgress():
      case SplashCacheDeleted():
        break;
    }
  }

  Future<void> _handleSplashFailure(
    Object error, {
    required bool failedWhileClearing,
  }) async {
    if (failedWhileClearing &&
        (widget._flow == SplashFlow.resetWallet ||
            widget._flow == SplashFlow.deleteCache)) {
      final bool retry =
          await showDialogWithNoAndYesOptions(
            context: context,
            isBarrierDismissible: false,
            title: widget._flow == SplashFlow.resetWallet
                ? context.l10n.walletResetFailed
                : context.l10n.cacheDeletionFailed,
            content: Text(
              context.l10n.failedToClearLocalWalletData(error.toString()),
            ),
          ) ??
          false;
      if (!mounted) {
        return;
      }
      if (retry) {
        _startSplashFlow(force: true);
        return;
      }
    }

    if (!mounted) {
      return;
    }
    await Navigator.pushReplacementNamed(
      context,
      SyriusErrorWidget.route,
      arguments: CustomSyriusErrorWidgetArguments(error.toString()),
    );
  }

  void _navigateTo(BuildContext context, SplashDestination destination) {
    switch (destination) {
      case SplashDestination.accessWallet:
        Navigator.pushReplacementNamed(context, AccessWalletScreen.route);
      case SplashDestination.home:
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed(MainAppContainer.route);
      case SplashDestination.nodeManagement:
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed(NodeManagementScreen.route);
    }
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }
}
