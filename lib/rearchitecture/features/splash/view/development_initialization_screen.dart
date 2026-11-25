import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Fast startup screen used during development to bypass the splash animation.
class DevelopmentInitializationScreen extends StatelessWidget {
  /// Creates a [DevelopmentInitializationScreen].
  const DevelopmentInitializationScreen({
    this._splashBloc,
    this._initApp,
    super.key,
  });

  /// Named route for [DevelopmentInitializationScreen].
  static const String route = 'development-initialization-screen';

  final SplashBloc? _splashBloc;
  final Future<void> Function(BuildContext context)? _initApp;

  @override
  Widget build(BuildContext context) {
    final Widget view = _View(initApp: _initApp ?? InitUtils.initApp);
    final SplashBloc? injectedBloc = _splashBloc;
    if (injectedBloc != null) {
      return BlocProvider<SplashBloc>.value(value: injectedBloc, child: view);
    }

    return BlocProvider<SplashBloc>(create: (_) => SplashBloc(), child: view);
  }
}

class _View extends StatefulWidget {
  const _View({required this._initApp});

  final Future<void> Function(BuildContext context) _initApp;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SplashBloc>().add(
        SplashStarted(
          flow: SplashFlow.development,
          initApp: () async {
            if (mounted) {
              await widget._initApp(context);
            }
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashBloc, SplashState>(
      listener: _onSplashStateChanged,
      builder: (BuildContext context, SplashState state) {
        return switch (state) {
          SplashFailure(:final Object error) => Text(
            context.l10n.errorWithMessage(error.toString()),
          ),
          SplashNavigateTo() => const SizedBox.shrink(),
          _ => const Center(child: CircularProgressIndicator()),
        };
      },
    );
  }

  void _onSplashStateChanged(BuildContext context, SplashState state) {
    if (state case SplashNavigateTo(:final SplashDestination destination)) {
      switch (destination) {
        case SplashDestination.accessWallet:
          Navigator.pushReplacementNamed(context, AccessWalletScreen.route);
        case SplashDestination.home:
        case SplashDestination.nodeManagement:
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushReplacementNamed(MainAppContainer.route);
      }
    }
  }
}
