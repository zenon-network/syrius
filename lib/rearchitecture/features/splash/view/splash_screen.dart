import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Animated startup screen coordinating app initialization, cache deletion,
/// and wallet reset flows.
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
  Timer? _initTimer;
  bool _initScheduled = false;

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
      if (!mounted || _initScheduled) {
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
      if (!mounted || _initScheduled) {
        return;
      }
      _initScheduled = true;
      _startSplashFlow();
    }
  }

  void _startSplashFlow() {
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
      child: FutureBuilder<LottieComposition>(
        future: _composition,
        builder:
            (BuildContext context, AsyncSnapshot<LottieComposition> snapshot) {
              final LottieComposition? composition = snapshot.data;
              if (composition != null) {
                return Lottie(composition: composition, repeat: false);
              }
              return const Center(child: CircularProgressIndicator());
            },
      ),
    );
  }

  void _onSplashStateChanged(BuildContext context, SplashState state) {
    switch (state) {
      case SplashNavigateTo(:final SplashDestination destination):
        _navigateTo(context, destination);
      case SplashFailure(:final Object error):
        Navigator.pushReplacementNamed(
          context,
          SyriusErrorWidget.route,
          arguments: CustomSyriusErrorWidgetArguments(error.toString()),
        );
      case SplashInitial():
      case SplashInProgress():
      case SplashCacheDeleted():
        break;
    }
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
    super.dispose();
  }
}
