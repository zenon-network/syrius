import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

/// [ReownSign] subclass that attaches an error handler to the fire-and-forget
/// `wc_sessionDelete` request sent by [disconnectSession].
///
/// In `reown_sign` 1.4.1, [ReownSign.disconnectSession] invokes
/// `core.pairing.sendRequest(topic, MethodConstants.WC_SESSION_DELETE, ...)`
/// without awaiting it or attaching an error handler, allowing an offline or
/// failing relay to surface an unhandled async error. Overriding
/// [disconnectSession] runs entirely in the caller's zone (avoiding
/// cross-error-zone `runZonedGuarded` boundaries) while preserving upstream
/// validation, local session/key cleanup, and `onSessionDelete` broadcast
/// semantics.
class SafeDisconnectReownSign extends ReownSign {
  /// Creates a [SafeDisconnectReownSign] delegating store and core wiring to
  /// [ReownSign].
  SafeDisconnectReownSign({
    required super.core,
    required super.metadata,
    required super.proposals,
    required super.sessions,
    required super.pendingRequests,
    required super.sessionAuthRequests,
    required super.authKeys,
    required super.pairingTopics,
  });

  static final Logger _logger = Logger('WalletConnectService');

  bool _isInitialized = false;

  @override
  Future<void> init() async {
    await super.init();
    _isInitialized = true;
  }

  @override
  Future<void> disconnectSession({
    required String topic,
    required ReownSignError reason,
  }) async {
    if (!_isInitialized) {
      // ReownSignError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getInternalError(Errors.NOT_INITIALIZED).toSignError();
    }
    core.confirmOnlineStateOrThrow();

    try {
      await _validateDisconnectTopic(topic);

      if (sessions.has(topic)) {
        // Send the request to delete the session without blocking local
        // cleanup, attaching an error handler so asynchronous relay/crypto
        // failures never escape as unhandled zone errors or leak secret
        // material into logs.
        try {
          final WcSessionDeleteRequest deleteRequest = WcSessionDeleteRequest(
            code: reason.code,
            message: reason.message,
            data: reason.data,
          );
          unawaited(
            core.pairing
                .sendRequest(
                  topic,
                  MethodConstants.WC_SESSION_DELETE,
                  deleteRequest.toJson(),
                )
                .then<void>(
                  (_) {},
                  onError: (Object error, StackTrace _) {
                    _logSuppressedSessionDeleteError(
                      topic: topic,
                      error: error,
                    );
                  },
                ),
          );
        } on Object catch (error) {
          _logSuppressedSessionDeleteError(topic: topic, error: error);
        }

        await _deleteSessionLocally(topic);
      } else {
        await core.pairing.disconnect(topic: topic);
      }
    } on ReownSignError catch (error, s) {
      core.logger.e(
        '[$runtimeType] disconnectSession()',
        error: error,
        stackTrace: s,
      );
    }
  }

  Future<void> _validateDisconnectTopic(String topic) async {
    if (sessions.has(topic)) {
      if (await core.expirer.checkAndExpire(topic)) {
        // ReownSignError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw Errors.getInternalError(
          Errors.EXPIRED,
          context: 'session topic: $topic',
        ).toSignError();
      }
      return;
    }

    if (core.pairing.getStore().has(topic)) {
      await core.pairing.isValidPairingTopic(topic: topic);
      return;
    }

    // ReownSignError does not implement Error/Exception upstream.
    // ignore: only_throw_errors
    throw Errors.getInternalError(
      Errors.NO_MATCHING_KEY,
      context: "session or pairing topic doesn't exist: $topic",
    ).toSignError();
  }

  Future<void> _deleteSessionLocally(String topic) async {
    final SessionData? session = sessions.get(topic);
    if (session == null) {
      return;
    }
    await core.relayClient.unsubscribe(topic: topic);

    await sessions.delete(topic);
    await core.crypto.deleteKeyPair(session.self.publicKey);
    await core.crypto.deleteSymKey(topic);

    onSessionDelete.broadcast(SessionDelete(topic));
  }

  void _logSuppressedSessionDeleteError({
    required String topic,
    required Object error,
  }) {
    final String errorSummary;
    if (error is ReownSignError) {
      errorSummary = 'ReownSignError(code=${error.code})';
    } else if (error is ReownCoreError) {
      errorSummary = 'ReownCoreError(code=${error.code})';
    } else if (error is JsonRpcError) {
      errorSummary = 'JsonRpcError(code=${error.code})';
    } else {
      errorSummary = '${error.runtimeType}';
    }
    _logger.fine(
      'Suppressed unawaited wc_sessionDelete sendRequest error for topic '
      '$topic ($errorSummary)',
    );
  }
}

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

  late final IReownSign _safeReOwnSign = SafeDisconnectReownSign(
    core: core,
    metadata: metadata,
    proposals: super.reOwnSign.proposals,
    sessions: super.reOwnSign.sessions,
    pendingRequests: super.reOwnSign.pendingRequests,
    sessionAuthRequests: super.reOwnSign.sessionAuthRequests,
    authKeys: super.reOwnSign.authKeys,
    pairingTopics: super.reOwnSign.pairingTopics,
  );

  @override
  IReownSign get reOwnSign => _safeReOwnSign;

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
