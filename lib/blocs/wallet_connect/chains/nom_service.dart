import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/i_chain.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_request_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/link_icon.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Supported Network of Momentum (Zenon) WalletConnect chain identifiers.
enum NoMChainId {
  /// Zenon Alphanet (`zenon:1`).
  mainnet,

  /// Zenon Testnet (`zenon:3`).
  testnet,
}

/// Formats a [NoMChainId] as a CAIP-2 chain identifier (`zenon:<id>`).
extension NoMChainIdX on NoMChainId {
  /// Returns the CAIP-2 chain string for this chain identifier.
  String chain() {
    String name = '';

    switch (this) {
      case NoMChainId.mainnet:
        name = '1';
      case NoMChainId.testnet:
        name = '3';
    }

    return '${NoMService.namespace}:$name';
  }
}

/// Network of Momentum (Zenon) WalletConnect request handler for `znn_info`,
/// `znn_sign`, and `znn_send`.
class NoMService extends IChain {
  /// Creates a [NoMService] bound to the configured WalletConnect client.
  NoMService({
    required this.reference,
    @visibleForTesting IWeb3WalletService? web3WalletService,
  }) : _web3WalletService = web3WalletService ?? sl<IWeb3WalletService>() {
    wallet = _web3WalletService.getWeb3Wallet();
  }

  /// CAIP-2 namespace for Zenon Network.
  static const String namespace = 'zenon';

  final IWeb3WalletService _web3WalletService;
  final Logger _logger = Logger('NoMWalletConnectService');

  /// Chain identifier handled by this service instance.
  final NoMChainId reference;

  final ReownCoreError _walletLockedError = const ReownCoreError(
    code: 9000,
    message: 'Wallet is locked',
  );

  /// Underlying [ReownWalletKit] client instance.
  ReownWalletKit? wallet;
  final Map<String, Future<dynamic>> _interactiveRequestFutures =
      <String, Future<dynamic>>{};

  @override
  String getNamespace() {
    return namespace;
  }

  @override
  String getChainId() {
    return reference.chain();
  }

  @override
  List<String> getEvents() {
    return <String>['chainIdChange', 'addressChange'];
  }

  /// Handles a `znn_info` session request with single-flight deduplication.
  Future<dynamic> handleZnnInfo(
    String topic,
    dynamic params, {
    int? requestId,
  }) {
    // znn_info approval does not depend on params, so without a request id
    // the key stays topic-scoped.
    final String key = interactiveRequestKey(
      method: 'znn_info',
      topic: topic,
      params: null,
      requestId: requestId,
    );
    return _runSingleFlight(key, () => _methodZnnInfo(topic, params));
  }

  /// Handles a `znn_sign` session request with single-flight deduplication.
  Future<dynamic> handleZnnSign(
    String topic,
    dynamic params, {
    int? requestId,
  }) {
    final String key = interactiveRequestKey(
      method: 'znn_sign',
      topic: topic,
      params: params,
      requestId: requestId,
    );
    return _runSingleFlight(key, () => _methodZnnSign(topic, params));
  }

  /// Handles a `znn_send` session request with single-flight deduplication.
  Future<dynamic> handleZnnSend(
    String topic,
    dynamic params, {
    int? requestId,
  }) {
    final String key = interactiveRequestKey(
      method: 'znn_send',
      topic: topic,
      params: params,
      requestId: requestId,
    );
    return _runSingleFlight(key, () => _methodZnnSend(topic, params));
  }

  SessionData _sessionByTopic(String topic) {
    return wallet!.getActiveSessions().values.firstWhere(
      (SessionData element) => element.topic == topic,
      orElse: () =>
          // ReownCoreError does not implement Error/Exception upstream.
          // ignore: only_throw_errors
          throw const ReownCoreError(
            code: 5001,
            message: 'WalletConnect session not found',
          ),
    );
  }

  String _resolveActiveAddress() {
    final String? selected = kSelectedAddress;
    if (selected == null || selected.isEmpty) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw const ReownCoreError(
        code: 5002,
        message: 'No selected address available',
      );
    }
    return selected;
  }

  /// Extracts an optional `fromAddress` string from WalletConnect request
  /// [params].
  @visibleForTesting
  static String? extractRequestedFromAddress(dynamic params) {
    if (params is Map) {
      final dynamic fromAddress = params['fromAddress'];
      if (fromAddress is String && fromAddress.isNotEmpty) {
        return fromAddress;
      }
    }
    return null;
  }

  /// Resolves the wallet address that will sign or submit a request, rejecting
  /// any requested `fromAddress` that is not owned by this wallet.
  @visibleForTesting
  String resolveSignerAddress({
    required String activeAddress,
    required String? requestedFromAddress,
    required String method,
    required String topic,
  }) {
    if (requestedFromAddress == null || requestedFromAddress.isEmpty) {
      return activeAddress;
    }

    final bool isWalletOwned = _isWalletOwnedAddress(requestedFromAddress);

    if (isWalletOwned) {
      if (requestedFromAddress != activeAddress) {
        _logger.info(
          'WalletConnect using requested fromAddress for method=$method '
          'topic=$topic requested=$requestedFromAddress active=$activeAddress',
        );
      }
      return requestedFromAddress;
    }

    _logger.warning(
      'WalletConnect requested fromAddress not wallet-owned; '
      'rejecting request - method=$method topic=$topic '
      'requested=$requestedFromAddress active=$activeAddress',
    );
    // ReownCoreError does not implement Error/Exception upstream.
    // ignore: only_throw_errors
    throw ReownCoreError(
      code: Errors.getSdkError(Errors.UNSUPPORTED_ACCOUNTS).code,
      message: 'fromAddress is not owned by this wallet',
    );
  }

  bool _isWalletOwnedAddress(String address) {
    return kAddressLabelMap.containsKey(address) ||
        kDefaultAddressList.contains(address);
  }

  Future<dynamic> _runSingleFlight(
    String key,
    Future<dynamic> Function() action,
  ) {
    final Future<dynamic>? existing = _interactiveRequestFutures[key];
    if (existing != null) {
      _logger.fine('Reusing in-flight interactive request: $key');
      return existing;
    }

    final Future<dynamic> future = action();
    _interactiveRequestFutures[key] = future;
    unawaited(
      future.whenComplete(() => _interactiveRequestFutures.remove(key)),
    );
    return future;
  }

  Future<dynamic> _methodZnnInfo(String topic, dynamic params) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }
    final SessionData session = _sessionByTopic(topic);
    final PairingMetadata dAppMetadata = session.peer.metadata;
    final String dAppName = _dAppName(dAppMetadata);
    final String dAppDescription = _dAppDescription(dAppMetadata);
    final String? dAppUrl = _dAppUrl(dAppMetadata);
    final String? dAppIconUrl = _dAppIconUrl(dAppMetadata);

    final String activeAddress = _resolveActiveAddress();
    _logger.info(
      'WalletConnect request method=znn_info topic=$topic '
      'activeAddress=$activeAddress',
    );

    final BuildContext? context = globalNavigatorKey.currentContext;
    if (kCurrentPage != Tabs.lock && context != null && context.mounted) {
      final bool? actionWasAccepted = await showDialogWithNoAndYesOptions(
        context: context,
        isBarrierDismissible: false,
        title: '$dAppName - Information',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Are you sure you want to allow $dAppName to '
              'retrieve the current address, node URL and chain identifier '
              'information?',
            ),
            kVerticalSpacing,
            if (dAppIconUrl != null)
              Image(
                image: NetworkImage(dAppIconUrl),
                height: 100,
                fit: BoxFit.fitHeight,
              ),
            kVerticalSpacing,
            Text(dAppDescription),
            kVerticalSpacing,
            if (dAppUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(dAppUrl, overflow: TextOverflow.ellipsis),
                  ),
                  LinkIcon(url: dAppUrl),
                ],
              ),
          ],
        ),
      );

      if (actionWasAccepted ?? false) {
        return <String, Object?>{
          'address': activeAddress,
          'nodeUrl': kCurrentNode,
          'chainId': getChainIdentifier(),
        };
      } else {
        await NotificationUtils.sendNotificationError(
          Errors.getSdkError(Errors.USER_REJECTED),
          'You have rejected the WalletConnect request',
        );
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw Errors.getSdkError(Errors.USER_REJECTED);
      }
    } else {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }
  }

  Future<dynamic> _methodZnnSign(String topic, dynamic params) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }
    final SessionData session = _sessionByTopic(topic);
    final PairingMetadata dAppMetadata = session.peer.metadata;
    final String dAppName = _dAppName(dAppMetadata);
    final String dAppDescription = _dAppDescription(dAppMetadata);
    final String? dAppUrl = _dAppUrl(dAppMetadata);
    final String? dAppIconUrl = _dAppIconUrl(dAppMetadata);
    final String activeAddress = _resolveActiveAddress();
    final String? requestedFromAddress = extractRequestedFromAddress(params);
    final String signerAddress = resolveSignerAddress(
      activeAddress: activeAddress,
      requestedFromAddress: requestedFromAddress,
      method: 'znn_sign',
      topic: topic,
    );

    final BuildContext? context = globalNavigatorKey.currentContext;
    if (kCurrentPage != Tabs.lock && context != null && context.mounted) {
      final String message = params is String
          ? params
          : (params is Map ? (params['message']?.toString() ?? '') : '');
      _logger.info(
        'WalletConnect request method=znn_sign topic=$topic '
        'activeAddress=$activeAddress requestedFrom=$requestedFromAddress',
      );

      final bool? actionWasAccepted = await showDialogWithNoAndYesOptions(
        context: context,
        isBarrierDismissible: false,
        title: '$dAppName - Sign Message',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Are you sure you want to sign message $message ?'),
            kVerticalSpacing,
            Text('Signing address: $signerAddress'),
            kVerticalSpacing,
            if (dAppIconUrl != null)
              Image(
                image: NetworkImage(dAppIconUrl),
                height: 100,
                fit: BoxFit.fitHeight,
              ),
            kVerticalSpacing,
            Text(dAppDescription),
            kVerticalSpacing,
            if (dAppUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(dAppUrl, overflow: TextOverflow.ellipsis),
                  ),
                  LinkIcon(url: dAppUrl),
                ],
              ),
          ],
        ),
      );

      if (actionWasAccepted ?? false) {
        final Signature signature = await walletSign(
          message.codeUnits,
          address: signerAddress,
        );
        return signature.signature;
      } else {
        await NotificationUtils.sendNotificationError(
          Errors.getSdkError(Errors.USER_REJECTED),
          'You have rejected the WalletConnect request',
        );
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw Errors.getSdkError(Errors.USER_REJECTED);
      }
    } else {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }
  }

  Future<dynamic> _methodZnnSend(String topic, dynamic params) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }
    final SessionData session = _sessionByTopic(topic);
    final PairingMetadata dAppMetadata = session.peer.metadata;
    final String dAppName = _dAppName(dAppMetadata);
    final String dAppDescription = _dAppDescription(dAppMetadata);
    final String? dAppUrl = _dAppUrl(dAppMetadata);
    final String? dAppIconUrl = _dAppIconUrl(dAppMetadata);
    final String activeAddress = _resolveActiveAddress();
    final String? requestedFromAddress = extractRequestedFromAddress(params);
    final String signerAddress = resolveSignerAddress(
      activeAddress: activeAddress,
      requestedFromAddress: requestedFromAddress,
      method: 'znn_send',
      topic: topic,
    );

    if (kCurrentPage == Tabs.lock) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }

    if (params is! Map || params['accountBlock'] is! Map) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw const ReownCoreError(
        code: 5003,
        message: 'Invalid accountBlock parameters',
      );
    }

    final Map<String, dynamic> accountBlockJson = Map<String, dynamic>.from(
      params['accountBlock'] as Map<dynamic, dynamic>,
    );
    final AccountBlockTemplate accountBlock = AccountBlockTemplate.fromJson(
      accountBlockJson,
    );

    _logger.info(
      'WalletConnect request method=znn_send topic=$topic '
      'activeAddress=$activeAddress requestedFrom=$requestedFromAddress '
      'to=${accountBlock.toAddress}',
    );

    final String toAddress = ZenonAddressUtils.getLabel(
      accountBlock.toAddress.toString(),
    );

    final Token? token = await zenon!.embedded.token.getByZts(
      accountBlock.tokenStandard,
    );
    if (token == null) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw ReownCoreError(
        code: 5004,
        message: 'Unknown token standard ${accountBlock.tokenStandard}',
      );
    }

    final String amount = accountBlock.amount.addDecimals(token.decimals);

    final BuildContext? context = globalNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw _walletLockedError;
    }

    final bool? wasActionAccepted = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: false,
      title: '$dAppName - Send Payment',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Are you sure you want to transfer '
            '$amount ${token.symbol} to '
            '$toAddress ?',
          ),
          kVerticalSpacing,
          Text('Source address: $signerAddress'),
          kVerticalSpacing,
          if (dAppIconUrl != null)
            Image(
              image: NetworkImage(dAppIconUrl),
              height: 100,
              fit: BoxFit.fitHeight,
            ),
          kVerticalSpacing,
          Text(dAppDescription),
          kVerticalSpacing,
          if (dAppUrl != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text(dAppUrl, overflow: TextOverflow.ellipsis),
                ),
                LinkIcon(url: dAppUrl),
              ],
            ),
        ],
      ),
      description:
          'Are you sure you want to transfer '
          '$amount ${token.symbol} to '
          '$toAddress from $signerAddress ?',
    );

    if (wasActionAccepted ?? false) {
      final SendTransactionBloc sendPaymentBloc = SendTransactionBloc();
      try {
        sendPaymentBloc.add(
          SendTransactionInitiateFromBlock(
            block: AccountBlockTemplate.fromJson(accountBlockJson),
            fromAddress: signerAddress,
            reasonForGeneratingPlasma: 'Execute transfer',
          ),
        );

        final SendTransactionState result = await sendPaymentBloc.stream
            .firstWhere(
              (SendTransactionState element) =>
                  element.status == .success || element.status == .failure,
            );

        if (result.status == .success) {
          return result.data;
        } else {
          throw result.error!;
        }
      } finally {
        unawaited(sendPaymentBloc.close());
      }
    } else {
      await NotificationUtils.sendNotificationError(
        Errors.getSdkError(Errors.USER_REJECTED),
        'You have rejected the WalletConnect request',
      );
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw Errors.getSdkError(Errors.USER_REJECTED);
    }
  }

  String _dAppName(PairingMetadata metadata) {
    return _metadataValue(metadata.name, 'Unknown dApp');
  }

  String _dAppDescription(PairingMetadata metadata) {
    return _metadataValue(metadata.description, 'No description provided');
  }

  String? _dAppUrl(PairingMetadata metadata) {
    final String value = _metadataValue(metadata.url, '');
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return value;
  }

  String? _dAppIconUrl(PairingMetadata metadata) {
    for (final String icon in metadata.icons) {
      final String value = _metadataValue(icon, '');
      final Uri? uri = Uri.tryParse(value);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return value;
      }
    }
    return null;
  }

  String _metadataValue(String value, String fallback) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return fallback;
    }
    return trimmed;
  }
}
