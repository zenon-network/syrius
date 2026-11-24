import 'package:flutter/widgets.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

/// Initializes the locked Reown signing engine on desktop targets.
///
/// Reown WalletKit 1.5.1 unconditionally initializes WalletConnect Pay, whose
/// locked native plugin supports only Android and iOS. The desktop wallet uses
/// the signing engine; payment links remain explicitly unsupported here.
class DesktopSigningWalletKit extends ReownWalletKit {
  /// Creates the desktop signing client without a native payment initializer.
  DesktopSigningWalletKit({required super.core, required super.metadata});

  Future<void>? _initialization;
  bool _initialized = false;

  @override
  WalletConnectPay get pay => throw UnsupportedError(
    'WalletConnect Pay is not available in this desktop wallet.',
  );

  @override
  Future<void> init() {
    if (_initialized) return Future<void>.value();
    return _initialization ??= _initializeSigning().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initializeSigning() async {
    await core.start();
    core.events.setQueryParams(<String, String>{
      'projectId': core.projectId,
      'st': 'events_sdk',
      'sv': ReownCoreUtils.coreSdkVersion(packageVersion),
    });
    await core.events.sendStoredEvents();
    await reOwnSign.init();
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
  }
}
